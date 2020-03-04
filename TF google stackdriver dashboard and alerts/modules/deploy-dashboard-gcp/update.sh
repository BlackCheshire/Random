for ID in $(gcloud alpha monitoring dashboards list --format=json | jq -r '.[].name' | awk -F'/' '{print $4}') 
do 
    if [[ $ID -eq $1 ]]; then 
        gcloud alpha monitoring dashboards update $ID --config-from-file=$3 --project=$2 
    fi 
done 