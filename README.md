1. 各種リソース作成, IAM 管理者 のロールをもつサービスアカウントを作成
2. サービスアカウントキーを credentials.json にリネームして本リポジトリルートに配置
3. GCP console 上で resource manager API を有効化
4. gcloud 認証
    ```sh
    gcloud auth login --cred-file=./credentials.json
    ```
5. terraform 実行（TODO: この時点では Cloud Run 作成を無効化する）
    ```sh
    terraform init
    terraform plan
    terraform apply
    ```
6. イメージの push
    ```sh
    bash ./setup_image.sh
    ```
7. terraform 再実行
    ```sh
    terraform init
    terraform plan
    terraform apply
    ```