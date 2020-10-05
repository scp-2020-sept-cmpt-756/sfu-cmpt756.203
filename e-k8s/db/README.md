# abstracted DB service example
This is an example of a service written in python.
You are free to look at this example as to what a service that would have the sole role of db querying would look like.

Feel free to replace this with another service in another language that you are most comfortable in. 

In addition, I have chosen to use a config file in the root folder for things like keys. It is a contentious matter how keys are stored in general - so feel free to do what you want regarding secrets management (maybe you want to use environment files in your docker container... maybe you want to integrate your deployment infrastructure with S3 buckets for configuration files...).

Caveat to this program running: you should have a table already in DynamoDB via AWS Console or CLI. You could also write your own endpoint on creating items in the DB.