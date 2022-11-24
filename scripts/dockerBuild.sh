docker build . -t python-app
image_id=$(sudo docker images --filter "reference=python-app" --quiet)
tag=$GITHUB_RUN_NUMBER
docker tag $image_id manish3097/python-app:$tag
docker push manish3097/python-app:$tag