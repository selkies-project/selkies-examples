#!/bin/bash

# Copyright 2021 The Selkies Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

EXCLUDE_REGIONS="$1"

# Get all cluster name, regions and node pool urls (for zones)
gcloud container clusters list -q --filter='name~broker-' --format='csv[no-heading](name,zone,instanceGroupUrls)' > clusters.txt

# Extract uniqe zones from all node pool urls.
ZONES=""
count=0
rm -f cluster_region_zone_tmp.txt
while IFS= read -r line; do
    IFS=',' read -ra CLUSTER <<< "$line"
    IFS=';' read -ra URLS <<< "${CLUSTER[2]}"
    if [[ "${EXCLUDE_REGIONS}" != "none" && "${EXCLUDE_REGIONS}" =~ "${CLUSTER[1]}" ]] ; then
        continue
    fi
    for url in ${URLS[*]}; do
        zone=$(echo "$url" | cut -d'/' -f9)
        if [[ -z "$ZONES" ]]; then ZONES=$zone; else ZONES=$ZONES:$zone; fi
        ((count=count+1))

        # Write provisioning zone and region to file
        echo "$zone,${CLUSTER[1]}" >> cluster_region_zone_tmp.txt
    done
done < "clusters.txt"

sort cluster_region_zone_tmp.txt | uniq > cluster_region_zone.txt
rm -f cluster_region_zone_tmp.txt

# Save list of zones to file
echo $ZONES | tr ':' '\n' | sort | uniq > zones.txt
