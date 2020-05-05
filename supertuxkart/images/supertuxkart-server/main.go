package main

import (
    "encoding/json"
    "flag"
    "fmt"
    "io"
    "io/ioutil"
    "log"
    "math"
    "net"
    "net/http"
    "os"
    "os/exec"
    "regexp"
    "sort"
    "strconv"
    "strings"
    "time"
    
    "github.com/prometheus/client_golang/prometheus"
)

type interceptor struct {
	forward   io.Writer
	intercept func(p []byte)
}

// Write will intercept the incoming stream, and forward
// the contents to its `forward` Writer.
func (i *interceptor) Write(p []byte) (n int, err error) {
	if i.intercept != nil {
		i.intercept(p)
	}

	return i.forward.Write(p)
}

var numPlayers int64
var maxPlayers *int64

type serverPlayers struct {
    Server string `json:"server"`
    NumPlayers int64 `json:"numPlayers"`
    MaxPlayers int64 `json:"maxPlayers"`
}

const stkPlayersConnectedMetric = "stk_players_connected"

func init() {
	http.HandleFunc("/healthz", healthzHandler)
    http.HandleFunc("/players", playersHandler)
    http.HandleFunc("/match", matchMakerHandler)
    http.HandleFunc("/servers", serverLoadHandler)
    http.Handle("/metrics", prometheus.Handler())
    
    startMetrics()
}

func main() {
    input := flag.String("f", "", "path to server log")
    readyPort := flag.Int64("ready-port", 8080, "port to expose readiness http server on")
    maxPlayers = flag.Int64("max-players", 8, "max connected users before becoming unready")
	flag.Parse()

    if len(*input) == 0 {
        *input = "/var/log/stk/server_config.log"
    }

    fmt.Printf("Watching log file: %s", *input)

    userPattern := regexp.MustCompile(".*There are now ([0-9]+) peers.")

    cmd := exec.Command("/usr/bin/tail", "-F", *input)
	cmd.Stderr = &interceptor{forward: os.Stderr}
	cmd.Stdout = &interceptor{
		forward: os.Stdout,
		intercept: func(p []byte) {
            str := strings.TrimSpace(string(p))

            res := userPattern.FindSubmatch([]byte(str))
            if len(res) > 0 {
                numPlayers, _ = strconv.ParseInt(string(res[1]), 10, 64)
            }

            fmt.Printf(">>> Current number of users connected: %d\n", numPlayers)
        },
    }

    err := cmd.Start()
    if err != nil {
        log.Fatalf("Failed to tail log: %s: %v", input, err)
    }

    log.Printf("Starting to listen on :%d", *readyPort)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%d", *readyPort), nil))
}

func healthzHandler(w http.ResponseWriter, r *http.Request) {
    if numPlayers < *maxPlayers {
        fmt.Fprintf(w, "OK")    
    } else {
        w.WriteHeader(http.StatusServiceUnavailable)
        fmt.Fprintf(w, "Too many users")
    }
}

func serverLoadHandler(w http.ResponseWriter, r *http.Request) {
    servers, err := getServers()
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        fmt.Fprintf(w, "%v", err)
        return
    }
    data, err := json.Marshal(&servers)
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        fmt.Fprintf(w, "%v", err)
        return
    }
    w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, string(data))
}

func playersHandler(w http.ResponseWriter, r *http.Request) {
    myIP := os.Getenv("POD_IP")
    serverPort := os.Getenv("STK_SERVER_PORT")
    
    server := serverPlayers{
        Server: fmt.Sprintf("%s:%s", myIP, serverPort),
        NumPlayers: numPlayers,
        MaxPlayers: *maxPlayers,
    }
    data, err := json.Marshal(&server)
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        fmt.Fprintf(w, "%v", err)
        return
    }
    w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, string(data))
}

func matchMakerHandler(w http.ResponseWriter, r *http.Request) {
    // Lookup the headless service DNS record, for each server listed, query the metrics endpoint to see how many players are connected.
    // Return the server ip of the server with the most players if not greater than half the max players
    servers, err := getServers()
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        fmt.Fprintf(w, "%v", err)
        return
    }

    if len(servers) == 0 {
        w.WriteHeader(http.StatusServiceUnavailable)
        fmt.Fprintf(w, "No servers available")
        return
    }
    
    // find server with most players
    match := servers[0].Server
    var loadFactor float64
    for _, server := range servers {
        serverLoadFactor := float64(server.NumPlayers) / float64(server.MaxPlayers)
        if  serverLoadFactor > loadFactor && math.Abs(float64(server.MaxPlayers - server.NumPlayers)) > 2 {
            match = server.Server
            loadFactor = serverLoadFactor
        }
    }

    w.WriteHeader(http.StatusOK)
    fmt.Fprintf(w, match)
}

func startMetrics() {
    // Register the prometheus metric.
    numPlayersMetric := prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: stkPlayersConnectedMetric,
			Help: "Number of players connected to Super Tux Kart server",
		},
	)
    prometheus.MustRegister(numPlayersMetric)

    ticker := time.NewTicker(5 * time.Second)
    quit := make(chan struct{})

    go func() {
		for {
			select {
			case <-ticker.C:

				// Publish metric
                numPlayersMetric.Set(float64(numPlayers))

			case <-quit:
				ticker.Stop()
				return
			}
		}
	}()
}

func getServers() ([]serverPlayers, error) {
    servers := make([]serverPlayers, 0)
    serverDNS := os.Getenv("STK_SERVER_DNS")
    ips, err := net.LookupIP(serverDNS)
    if err != nil {
        return servers, err
    }
    for _, ip := range ips {
        // Fetch number of players from server
        resp, err := http.Get(fmt.Sprintf("http://%s:8080/players", ip))
        if err != nil {
            return servers, err
        }
        defer resp.Body.Close()
        body, err := ioutil.ReadAll(resp.Body)
        if err != nil {
            return servers, err
        }
        var server serverPlayers
        json.Unmarshal(body, &server)
        servers = append(servers, server)
        resp.Body.Close()
    }
    sort.Slice(servers[:], func(i, j int) bool {
        return servers[i].Server < servers[j].Server
    })
    return servers, err
}