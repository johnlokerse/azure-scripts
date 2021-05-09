gh secret set AZURE_CREDENTIALS \
    -b "$(az ad sp create-for-rbac --name 'my-sp-name' --sdk-auth -o json)"