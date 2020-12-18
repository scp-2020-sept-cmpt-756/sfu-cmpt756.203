#
# Janky front-end to bring some sanity (?) to the litany of tools and switches
# in setting up, tearing down and validating your Minikube cluster for working
# with k8s and istio.
#
# This file covers off driving the API independent of where the cluster is
# running.
# Be sure to set your context appropriately for the log monitor.
#
# The intended approach to working with this makefile is to update select
# elements (body, id, IP, port, etc) as you progress through your workflow.
# Where possible, stodout outputs are tee into .out files for later review.
#


KC=kubectl
CURL=curl

# look these up with 'make ls'
# You need to specify the container because istio injects side-car container
# into each pod.
# s1: service1; s2: service2; db: cmpt756db
PODS1=pod/cmpt756s1-8557865b4b-jnwrj
PODCONT=service1

logs:
	$(KC) logs $(PODS1) -c $(PODCONT)

#
# Replace this with the external IP/DNS name of your cluster
#
# In all cases, look up the external IP of the istio-ingressgateway LoadBalancer service
# You can use either 'make -f eks.m extern' or 'make -f mk.m extern' or
# directly 'kubectl -n istio-system get service istio-ingressgateway'
#
#IGW=172.16.199.128:31413
#IGW=10.96.57.211:80
#IGW=a344add95f74b453684bcd29d1461240-517644147.us-east-1.elb.amazonaws.com:80
#IGW=localhost:80
IGW=127.0.0.1:80

# stock body & fragment for API requests
BODY_USER= { \
"fname": "Sherlock", \
"email": "sholmes@baker.org", \
"lname": "Holmes" \
}

BODY_UID= { \
    "uid": "dbfbc1c0-0783-4ed7-9d78-08aa4a0cda02" \
}

ARTIST="Duran Duran"
SONGTITLE="Rio"

BODY_MUSIC= { \
  "Artist": "$(ARTIST)", \
  "SongTitle": "$(SONGTITLE)" \
}

# this is a token for ???
TOKEN=Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZGJmYmMxYzAtMDc4My00ZWQ3LTlkNzgtMDhhYTRhMGNkYTAyIiwidGltZSI6MTYwNzM2NTU0NC42NzIwNTIxfQ.zL4i58j62q8mGUo5a0SQ7MHfukBUel8yl8jGT5XmBPo
BODY_TOKEN={ \
    "jwt": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiZGJmYmMxYzAtMDc4My00ZWQ3LTlkNzgtMDhhYTRhMGNkYTAyIiwidGltZSI6MTYwNzM2NTU0NC42NzIwNTIxfQ.zL4i58j62q8mGUo5a0SQ7MHfukBUel8yl8jGT5XmBPo" \
}

# keep these ones around
USER_ID=dbfbc1c0-0783-4ed7-9d78-08aa4a0cda02
MUSIC_ID=372bb8aa-eecb-482e-bc12-7dfec6080910

# it's convenient to have a second set of id to test deletion (DELETE uses these id with the suffix of 2)
USER_ID2=27fac86c-321f-43aa-a9c9-6a7faefbd28d
MUISC_ID2=8ed63e4f-3b1e-47f8-beb8-3604516e5a2d


# POST is used for user (apipost) or music (apimusic) to create a new record
cuser:
	echo curl --location --request POST 'http://$(IGW)/api/v1/user/' --header 'Content-Type: application/json' --data-raw '$(BODY_USER)' > cuser.out
	$(CURL) --location --request POST 'http://$(IGW)/api/v1/user/' --header 'Content-Type: application/json' --data-raw '$(BODY_USER)' | tee -a cuser.out

cmusic:
	$(CURL) --location --request POST 'http://$(IGW)/api/v1/music/' --header '$(TOKEN)' --header 'Content-Type: application/json' --data-raw '$(BODY_MUSIC)'

# PUT is used for user (update) to update a record
uuser:
	echo curl --location --request PUT 'http://$(IGW)/api/v1/user/$(USER_ID)' --header '$(TOKEN)' --header 'Content-Type: application/json' --data-raw '$(BODY_USER)' > uuser.out
	$(CURL) --location --request PUT 'http://$(IGW)/api/v1/user/$(USER_ID)' --header '$(TOKEN)' --header 'Content-Type: application/json' --data-raw '$(BODY_USER)' | tee -a uuser.out

# GET is used with music to read a record
rmusic:
	echo curl --location --request GET 'http://$(IGW)/api/v1/music/$(MUSIC_ID)' --header '$(TOKEN)' > rmusic.out
	$(CURL) --location --request GET 'http://$(IGW)/api/v1/music/$(MUSIC_ID)' --header '$(TOKEN)' | tee -a rmusic.out

# DELETE is used with user or music to delete a record
duser:
	$(CURL) --location --request DELETE 'http://$(IGW)/api/v1/user/$(USER_ID2)' --header '$(TOKEN)'

dmusic:
	$(CURL) --location --request DELETE 'http://$(IGW)/api/v1/music/$(MUSIC_ID2)' --header '$(TOKEN)'

# PUT is used for login/logoff too
apilogin:
	echo curl --location --request PUT 'http://$(IGW)/api/v1/user/login' --header 'Content-Type: application/json' --data-raw '$(BODY_UID)' > apilogin.out
	$(CURL) --location --request PUT 'http://$(IGW)/api/v1/user/login' --header 'Content-Type: application/json' --data-raw '$(BODY_UID)' | tee -a apilogin.out

apilogoff:
	echo curl --location --request PUT 'http://$(IGW)/api/v1/user/logoff' --header 'Content-Type: application/json' --data-raw '$(BODY_TOKEN)' > apilogoff.out
	$(CURL) --location --request PUT 'http://$(IGW)/api/v1/user/logoff' --header 'Content-Type: application/json' --data-raw '$(BODY_TOKEN)' | tee -a apilogoff.out
