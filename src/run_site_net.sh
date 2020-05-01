docker run -d  --env-file=env.list --network=back_net -v reddit_db:/data/db  --name mongo_db_1 --network-alias=post_db_1 --network-alias=comment_db_1  mongo:latest
docker run -d --env-file=env.list --network=back_net --name post_1 --network-alias=post_1 avasiliev/post:1.0
docker run -d --env-file=env.list --network=back_net  --name comment_1  avasiliev/comment:1.0
docker run -d --env-file=env.list --network=front_net -p 9292:9292 --name ui avasiliev/ui:2.0


docker network connect front_net  post_1
docker network connect front_net  comment_1
