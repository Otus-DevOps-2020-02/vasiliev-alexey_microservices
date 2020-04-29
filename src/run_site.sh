docker run -d  --env-file=env.list --network=reddit --network-alias=post_db_1 --network-alias=comment_db_1 -v reddit_db:/data/db mongo:latest
docker run -d --env-file=env.list --network=reddit --network-alias=post_1 avasiliev/post:1.0
docker run -d --env-file=env.list --network=reddit --network-alias=comment_1 avasiliev/comment:1.0
docker run -d --env-file=env.list --network=reddit -p 9292:9292 avasiliev/ui:2.0
