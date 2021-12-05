#
# Front-end to bring some sanity to the litany of tools and switches
# in calling the sample application from the command line.
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

# Keep all the logs out of main directory
LOG_DIR=logs

# look these up with 'make ls'
# You need to specify the container because istio injects side-car container
# into each pod.
# s1: service1; s2: service2; db: cmpt756db
PODS1=pod/cmpt756s1-8557865b4b-jnwrj
PODCONT=service1

# show deploy and pods in current ns; svc of cmpt756 ns
ls: showcontext
	$(KC) get gw,deployments,pods
	$(KC) -n $(NS) get svc

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
IGW=EXTERN

# stock body & fragment for API requests
BODY_USER= { \
"fname": "Sherlock", \
"email": "sholmes@baker.org", \
"lname": "Holmes" \
}

BODY_UID= { \
    "uid": "0d2a2931-8be6-48fc-aa9e-5a0f9f536bd3" \
}

BODY_MUSIC= { \
  "Artist": "Duran Duran", \
  "SongTitle": "Rio" \
}

# this is a token for ???
TOKEN=Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiMDI3Yzk5ZWYtM2UxMi00ZmM5LWFhYzgtMTcyZjg3N2MyZDI0IiwidGltZSI6MTYwMTA3NDY0NC44MTIxNjg2fQ.hR5Gbw5t2VMpLcj8yDz1B6tcWsWCFNiHB_KHpvQVNls
BODY_TOKEN={ \
    "jwt": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiMDI3Yzk5ZWYtM2UxMi00ZmM5LWFhYzgtMTcyZjg3N2MyZDI0IiwidGltZSI6MTYwMTA3NDY0NC44MTIxNjg2fQ.hR5Gbw5t2VMpLcj8yDz1B6tcWsWCFNiHB_KHpvQVNls" \
}

# keep these ones around
USER_ID=0d2a2931-8be6-48fc-aa9e-5a0f9f536bd3
MUSIC_ID=2995bc8b-d872-4dd1-b396-93fde2f4bfff

# it's convenient to have a second set of id to test deletion (DELETE uses these id with the suffix of 2)
USER_ID2=9175a76f-7c4d-4a3e-be57-65856c6bb77e
MUSIC_ID2=8ed63e4f-3b1e-47f8-beb8-3604516e5a2d


# POST is used for user (apipost) or music (apimusic) to create a new record
cuser:
	echo curl --location --request POST 'http://$(IGW)/api/v1/user/' --header 'Content-Type: application/json' --data-raw '$(BODY_USER)' > $(LOG_DIR)/cuser.out
	$(CURL) --location --request POST 'http://$(IGW)/api/v1/user/' --header 'Content-Type: application/json' --data-raw '$(BODY_USER)' | tee -a $(LOG_DIR)/cuser.out

cmusic:
	echo curl --location --request POST 'http://$(IGW)/api/v1/music/' --header '$(TOKEN)' --header 'Content-Type: application/json' --data-raw '$(BODY_MUSIC)' > $(LOG_DIR)/cmusic.out
	$(CURL) --location --request POST 'http://$(IGW)/api/v1/music/' --header '$(TOKEN)' --header 'Content-Type: application/json' --data-raw '$(BODY_MUSIC)' | tee -a $(LOG_DIR)/cmusic.out

# PUT is used for user (update) to update a record
uuser:
	echo curl --location --request PUT 'http://$(IGW)/api/v1/user/$(USER_ID)' --header '$(TOKEN)' --header 'Content-Type: application/json' --data-raw '$(BODY_USER)' > $(LOG_DIR)/uuser.out
	$(CURL) --location --request PUT 'http://$(IGW)/api/v1/user/$(USER_ID)' --header '$(TOKEN)' --header 'Content-Type: application/json' --data-raw '$(BODY_USER)' | tee -a $(LOG_DIR)/uuser.out

# GET is used with music to read a record
rmusic:
	echo curl --location --request GET 'http://$(IGW)/api/v1/music/$(MUSIC_ID)' --header '$(TOKEN)' > $(LOG_DIR)/rmusic.out
	$(CURL) --location --request GET 'http://$(IGW)/api/v1/music/$(MUSIC_ID)' --header '$(TOKEN)' | tee -a $(LOG_DIR)/rmusic.out

# DELETE is used with user or music to delete a record
duser:
	echo curl --location --request DELETE 'http://$(IGW)/api/v1/user/$(USER_ID2)' --header '$(TOKEN)' > $(LOG_DIR)/duser.out
	$(CURL) --location --request DELETE 'http://$(IGW)/api/v1/user/$(USER_ID2)' --header '$(TOKEN)' | tee -a $(LOG_DIR)/duser.out

dmusic:
	echo curl --location --request DELETE 'http://$(IGW)/api/v1/music/$(MUSIC_ID2)' --header '$(TOKEN)' > $(LOG_DIR)/dmusic.out
	$(CURL) --location --request DELETE 'http://$(IGW)/api/v1/music/$(MUSIC_ID2)' --header '$(TOKEN)' | tee -a $(LOG_DIR)/dmusic.out

# PUT is used for login/logoff too
apilogin:
	echo curl --location --request PUT 'http://$(IGW)/api/v1/user/login' --header 'Content-Type: application/json' --data-raw '$(BODY_UID)' > $(LOG_DIR)/apilogin.out
	$(CURL) --location --request PUT 'http://$(IGW)/api/v1/user/login' --header 'Content-Type: application/json' --data-raw '$(BODY_UID)' | tee -a $(LOG_DIR)/apilogin.out

apilogoff:
	echo curl --location --request PUT 'http://$(IGW)/api/v1/user/logoff' --header 'Content-Type: application/json' --data-raw '$(BODY_TOKEN)' > $(LOG_DIR)/apilogoff.out
	$(CURL) --location --request PUT 'http://$(IGW)/api/v1/user/logoff' --header 'Content-Type: application/json' --data-raw '$(BODY_TOKEN)' | tee -a $(LOG_DIR)/apilogoff.out


showcontext:
	$(KC) config get-contexts

