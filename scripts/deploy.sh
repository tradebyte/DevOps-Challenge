tag=$GITHUB_RUN_NUMBER
sed -i  "s/image: manish3097\/python-app/image: manish3097\/python-app:$tag/g" kubernetes/app.yaml
sudo microk8s kubectl apply -f kubernetes/config-maps.yaml -n dev
sudo microk8s kubectl apply -f kubernetes/app.yaml  -n dev
