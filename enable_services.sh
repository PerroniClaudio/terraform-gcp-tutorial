# Inizializza gcloud
gcloud init

# Crea un nuovo progetto
gcloud projects create $PROJECT_ID --name="$PROJECT_NAME" --set-as-default

# Abilita google cloud dns, compute engine, IAM 

gcloud services enable dns.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com

# Crea un account di servizio

gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME --display-name $SERVICE_ACCOUNT_NAME

# Assegna ruoli specifici all'account di servizio per i servizi utilizzati

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/dns.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin"

# Esporta la chiave dell'account di servizio in formato JSON

gcloud iam service-accounts keys create ~/service-account.json \
        --iam-account $SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com

# Crea una zona dns 

gcloud dns --project=dgvery managed-zones create terraform-gcp --description="" --dns-name="test.iftzone.com." --visibility="public" --dnssec-state="off"