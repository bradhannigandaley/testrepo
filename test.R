# Load Initial Libraries
suppressMessages(library(data.table))
suppressMessages(library(pander))
suppressMessages(library(RPostgreSQL))
suppressMessages(library(dplyr))
suppressMessages(library(mailR))
message("Loaded Required Libraries")

## Connection to Presto
presto_connection <- dbConnect(RPresto::Presto(), host='http://test.com', 
                                                  port=8080, 
                                                  user='vincentyeung-BI', 
                                                  schema='adroll', 
                                                  catalog = 'hive')

date <- data.table(dbGetQuery(presto_connection, paste0( 
                   "SELECT
                      MAX(date) as max_date
                    FROM
                      bi.rtbcube_country
                    ")))

last_date <- as.Date(date$max_date)
first_date <- last_date - 7

datadog <- data.table(dbGetQuery(presto_connection, paste0( 
                   "SELECT
                      campaign_eid,
                      country,
                      SUM(total_spend) AS total_spend,
                      SUM(impressions) AS impressions
                    FROM
                      bi.rtbcube_country
                    WHERE
                      campaign_eid = 'L3Z7WYO5B5DPBPBEF68PRO' AND
                      date BETWEEN '", first_date, "' AND '", last_date, "' 
                    GROUP BY 1, 2
                    ORDER BY 3 DESC")))

datadog2 <- data.table(dbGetQuery(presto_connection, paste0( 
                   "SELECT
                      campaign_eid,
                      country,
                      SUM(total_spend) AS total_spend,
                      SUM(impressions) AS impressions
                    FROM
                      bi.rtbcube_country
                    WHERE
                      campaign_eid = 'Y5WJUNUOYJGJBLBCD48PRO' AND
                      date BETWEEN '", first_date, "' AND '", last_date, "'
                    GROUP BY 1, 2
                    ORDER BY 3 DESC")))

write.csv(datadog, paste0("datadog_web_prospecting_", last_date, ".csv"), row.names = FALSE)
write.csv(datadog2, paste0("datadog_web_prospecting_US_", last_date, ".csv"), row.names = FALSE)

sender <- 'adrollbi@adroll.com'
recipients <- c("vincent.yeung@adroll.com", "kirby.anderson@adroll.com", "chrissy.vailas@adroll.com")
email_subject <- paste("Datadog", last_date)
files <- c(paste0("./datadog_web_prospecting_", last_date, ".csv"), paste0("./datadog_web_prospecting_US_", last_date, ".csv"))
body_text <- paste0("Data is based off of ", first_date, " to ", last_date, ".", '<br><br>',
                    "Please contact Vincent Yeung if you have any questions.", '<br><br>',
                    "[This is an automatically generated email. Please do not reply directly to this e-mail.]")

email <- send.mail(from = sender,
                   to = recipients,
                   subject = email_subject,
                   body = body_text,
                   html = TRUE,
                   smtp = list(host.name = "smtp.gmail.com", port = 587, user.name = 'adrollbi@adroll.com', passwd = 'Adroll972!!', ssl=TRUE),
                   attach.files = files,
                   authenticate = TRUE,
                   send = TRUE)
