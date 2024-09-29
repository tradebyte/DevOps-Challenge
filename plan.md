1. jenkins on an ec2 instance
2. configure docker & ansible agents in jenkins
    2.1. docker agent is used to build the image then run tests then push it to an image registry
    2.2. ansible agent is used to configure the ec2 ( install docker & pull the image )
3. configure the notification channel in jenkins