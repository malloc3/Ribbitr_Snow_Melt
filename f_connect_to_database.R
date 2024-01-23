# This Script handles DB connections to the Ribbitr Database

# Change this to the location of your secrets (aka your Ribbitr login and password)
# Should be a CSV in format:
# user, password
# user_name, Your_PaSsWoRD
file_secrets = "/Users/Cannon/Documents/GitHub_Security_Codes/Is it this one/Lamo_you will never find me/Beep Beep/Ribbitr_Secrets/ribbitr_secrets.csv"

# Connect to database runs the code required for connecting to the Ribbitr Database
# It will pull from a "secrets" folder which you will need to set the path here!
#
# Output:
# ribbitr_connection = Connection the connection to the ribbitr database.
connect_to_database <- function(){
  secrets = read.csv(file_secrets) #fetches the secrets
  tryCatch({
    print("Connecting to Database...")
    ribbitr_connection <- dbConnect(drv = dbDriver("Postgres"),
                                    dbname = "ribbitr",
                                    host = "ribbitr.c6p56tuocn5n.us-west-1.rds.amazonaws.com",
                                    port = "5432",
                                    user = toString(secrets[1,1]),
                                    password = toString(secrets[1,2]))
    
    print("Database Connected!")
  },
  error=function(cond) {
    print("Unable to connect to Database.")
  })
  return(ribbitr_connection)
}