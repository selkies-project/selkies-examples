# Cronjob for updating the Image Cache

The image cache update requires that the broker Google Cloud Service Account has the `Cloud Build Service Account` role so that the job can invoke the build.

This role can be added with the command below:

```bash
export PROJECT_ID=your-project-id
```

```bash
BROKER_SA="broker@${PROJECT_ID?}.iam.gserviceaccount.com" && \
  gcloud projects add-iam-policy-binding ${PROJECT_ID?} --member serviceAccount:${BROKER_SA?} --role roles/cloudbuild.builds.builder
```