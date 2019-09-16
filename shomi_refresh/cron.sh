#!/usr/bin/expect -f

#send "cd GCL_portal\r"
#expect "rogers"

spawn heroku run rake localeapp:pull --app staging-shomi
expect "Starting Agent shutdown"

interact


