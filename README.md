# Useful scripts

# Set retest frequency for all projects of a target

```
./set_retest_frequency_to_null_for_target.sh SNYK_TOKEN ORG_ID TARGET_NAME USER_ID FREQUENCY
```

All Ids are UUIDs. Get your USER_ID using the following curl command:
```
curl -H 'Authorization: token SNYK_TOKEN' -H 'Content-type: application/vnd.api+json' https://api.snyk.io/rest/self
```

Adjust the api.snyk.io to other regions if needed.
