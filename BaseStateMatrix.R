library(tidyverse)
library(baseballr) # 'statcast_search_pitchers()' to get 2022 season pitch by pitch data


# Load pitching data

pdat <- read.csv()


# Order the pitches chronologically and filter the necessary columns

matrix <- pdat %>% arrange(game_pk, at_bat_number, pitch_number) %>% 
                    select(away_team, away_score, home_team, home_score, game_pk, inning_topbot,
                           inning, on_1b, on_2b, on_3b, post_away_score, post_home_score, at_bat_number, 
                           pitch_number, des, batter, outs_when_up, player_name, pitch_name,
                           delta_run_exp, events)



# Part 1: Create RE24 matrix


# 'RUNS' column contains the total runs in the game at the time of the pitch observation

matrix$RUNS <- with(matrix, away_score + home_score)


# 'BAT_HOME_ID' column creates a unique identifier for the batting team of each half inning

matrix$BAT_HOME_ID <- with(matrix, ifelse(inning_topbot == "Top", away_team, home_team))


# 'HALF.INN' column creates a unique identifier for each half inning

matrix$HALF.INN <- with(matrix, paste(game_pk, inning, BAT_HOME_ID))


# 'RUNS_SCORED' column creates the number of runs scored as a result of the pitch observed in that row

matrix$RUNS_SCORED <- with(matrix, ifelse(inning_topbot == "Top", (post_away_score - away_score), (post_home_score - home_score)))


# Create 'RUNS_SCORED_START' data frame that returns the total amount of runs scored at the start of each half inning and the half inning ID ('HALF.INN')
# aggregate() is used to paste the first value in the 'RUNS' column for each 'HALF.INN' 

RUNS_SCORED_START <- aggregate(matrix$RUNS, list(HALF.INN = matrix$HALF.INN), "[", 1)


# Create 'RUNS_SCORED_INN' data frame that returns the amount of runs scored in each half inning and the half inning id ('HALF.INN')
# aggregate() is used to sum the 'RUNS_SCORED' in each half inning

RUNS_SCORED_INN <- aggregate(matrix$RUNS_SCORED, list(HALF.INN = matrix$HALF.INN), sum)


# Create 'MAX' data frame to display the total runs scored in the game to that point for the batting team

  # Get the 'HALF.INN' identifier from previously created 'RUNS_SCORED_START' object
MAX <- data.frame(HALF.INN = RUNS_SCORED_START$HALF.INN)

  # Add the total amount runs scored in that inning to the amount of runs there were at the start of the inning to get the max runs
MAX$x <- RUNS_SCORED_INN$x + RUNS_SCORED_START$x


# Merge 'MAX' with the original 'matrix' object

matrix <- merge(matrix, MAX)


# Rename the column currently titled 'x' from 'MAX' object

  # Get the number of the 'x' column so it can be called in the following step
N <- ncol(matrix)

  # Change the column name to 'MAX_RUNS'
names(matrix)[N] <- "MAX_RUNS"


# 'RUNS_ROI' column displays the runs scored for the Rest Of the Inning by subtracting 'MAX_RUNS' from 'RUNS' for each row
# Remember 'RUNS' column contains the amount of runs scored on a particular pitch observation

matrix$RUNS_ROI <- with(matrix, MAX_RUNS - RUNS)


# Create get.state() function using the runner position and amount of outs in each pitch observation 
# 'STATE' example: bases empty no outs -> "000 0" | bases loaded 2 outs -> "111 2"

get.state <- function(runner1, runner2, runner3, outs){
  runners <- paste(runner1, runner2, runner3, sep="")
  paste(runners, outs)
}


# Create a variable for each base that will display 0 if no runner is on that base and 1 if there is a runner on that base

RUNNER1 <- ifelse(is.na(matrix$on_1b), 0, 1)
RUNNER2 <- ifelse(is.na(matrix$on_2b), 0, 1)
RUNNER3 <- ifelse(is.na(matrix$on_3b), 0, 1)


# Use get.state() function to make the 'STATE' column in the 'matrix' object

matrix$STATE <- get.state(RUNNER1, RUNNER2, RUNNER3, matrix$outs_when_up)


# Use coalesce() and lead() to create 'NEW_STATE' column, which is the 'STATE' directly following any particular pitch observation
# By creating a 'NEXT_STATE' value, the change in run expectancy can be calculated to create the Run Expectancy Matrix

matrix$NEW_STATE <- coalesce(lead(matrix$STATE), "000 0")


# Mutate the 'NEW_STATE' column so that the end of an inning does not display the 'NEW_STATE' as '000 0'

matrix$NEW_STATE <- ifelse(
  matrix$STATE %in% c('000 2', '100 2', '010 2', '001 2', '110 2', '011 2', '101 2', '111 2') & matrix$NEW_STATE == '000 0',
  '000 3',
  matrix$NEW_STATE
)


# 'AB_ID' is a unique identifier for each at bat of each game

matrix$AB_ID <- with(matrix, paste(at_bat_number, game_pk))


# Filter out incomplete innings
  # Missing values scattered throughout my particular scraped data frame made this task nearly impossible to execute perfectly
  # This was my best attempt

#matrix$outs_on_play <- with(matrix, case_when(events %in% c("", "double", "home_run", "single", "hit_by_pitch", "walk", "field_error", 
#                                                               "triple", "game_advisory", "catcher_interf", "wild_pitch") ~ 0,
#                                                 
#                                                 events %in% c("field_out", "strikeout", "fielders_choice_out", "force_out", "sac_fly", "sac_bunt",
#                                                               "fielders_choice", "caught_stealing_2b", "caught_stealing_3b", "other_out", "pickoff_2b",
#                                                               "pickoff_caught_stealing_3b", "pickoff_3b", "pickoff_1b", "caught_stealing_home",
#                                                               "pickoff_caught_stealing_home", "pickoff_caught_stealing_2b") ~ 1,
#                                                 
#                                                 events %in% c("grounded_into_double_play", "double_play", "sac_fly_double_play", 
#                                                               "strikeout_double_play") ~ 2,
#                                                 
#                                                 events == "triple_play" ~ 3))
#
#matrix$post_outs <- (matrix$outs_on_play + matrix$outs_when_up)
#
#
#pmatrix <- pmatrix %>% group_by(HALF.INN) %>% filter(post_outs == 3)

# Instead, I filtered out all 9th innings and beyond in a new variable called 'pmatrix'

pmatrix <- matrix %>% filter(inning <= 8)


# Subset 'pmatrix' again to filter only the observations when the 'STATE' changes or a run is scored, all other observations are useless here

pmatrix <- subset(pmatrix, (STATE != NEW_STATE | RUNS_SCORED > 0))


# Create 'RUNS', the Run Expectancy data frame
# The key is to get the average amount of runs scored from the point a base STATE to the end of a half inning to get the expected amount of runs in any given base state
# aggregate() is used to get the mean of 'RUNS_ROI' for each 'STATE'

RUNS <- with(pmatrix, aggregate(RUNS_ROI, list(STATE), mean))

# substr() is used to isolate the last value from the 'STATE' ('000 [2]') creating the 'Outs' column
RUNS$Outs <- substr(RUNS$Group.1, 5, 5)

# Order the Run Expectancy data frame by 'Outs'
RUNS <- RUNS[order(RUNS$Outs),]


# Create 'RUNS.out' which will displays the data frame as a matrix
# Round values and rename columns

RUNS.out <- matrix(round(RUNS$x, 2), 8, 3)
dimnames(RUNS.out)[[2]] <- c("0 outs", "1 out", "2 outs")
dimnames(RUNS.out)[[1]] <- c("000", "001", "010", "011", "100", "101", "110", "111")


# View the Run Expectancy matrix!

view(RUNS.out)


# Create 'RUNS_POTENTIAL' data frame to merge with 'pmatrix' 
# 'RUNS_POTENTIAL' will be used as the base value to measure changes in run expectancy for pitch by pitch data

RUNS_POTENTIAL <- matrix(c(RUNS$x, rep(0, 8)), 32, 1)
dimnames(RUNS_POTENTIAL) [[1]] <- c(RUNS$Group.1, "000 3", "001 3", "010 3", "011 3", "100 3", "101 3", "110 3", "111 3")


# 'RUNS_STATE' returns the amount of runs expected by the end of the half inning in the current observation's 'STATE'

pmatrix$RUNS_STATE <- RUNS_POTENTIAL[pmatrix$STATE, ]


# 'RUNS_NEW_STATE' returns the average amount of runs expected by the end of the half inning in the observation's following 'STATE'

pmatrix$RUNS_NEW_STATE <- RUNS_POTENTIAL[pmatrix$NEW_STATE, ]


# 'RUNS_VALUE' takes the difference between 'NEW_STATE' and 'RUNS_STATE' plus the amount of 'RUNS_SCORED' in that observation to calculate a change in expected runs

pmatrix$RUNS_VALUE <- pmatrix$RUNS_NEW_STATE - pmatrix$RUNS_STATE + pmatrix$RUNS_SCORED




# PART 2: Estimate the total change in run expectancy a pitcher was on the mound for this season

# Reminder that the data is filtered to not include 9th inning or later, so starting pitchers make sense to evaluate
# Batters can be evaluated too if your 'player_name' column has the batter's name instead of pitcher's


# Subset different pitchers from 'pmatrix'

cole <- subset(pmatrix, player_name == "Cole, Gerrit")
irvin <- subset(pmatrix, player_name == "Irvin, Cole")
sandy <- subset(pmatrix, player_name == "Alcantara, Sandy")


# Use substr() from the 'STATE' column to create the 'RUNNERS' column, which returns the position of the runners (0 or 1 depending if it is occupied)
# Use table() to view the amount of times the pitcher faced each possible base state

cole$RUNNERS <- substr(cole$STATE, 1, 3)
table(cole$RUNNERS)

irvin$RUNNERS <- substr(irvin$STATE, 1, 3)
table(irvin$RUNNERS)

sandy$RUNNERS <- substr(sandy$STATE, 1, 3)
table(sandy$RUNNERS)


# Use stripchart() and abline() to create a chart showing the distribution of 'RUNS_VALUE' (expected runs) in each possible base state

with(cole, stripchart(RUNS_VALUE ~ RUNNERS, vertical = TRUE, jitter = 0.2, xlab = "RUNNERS", method = "jitter", pch=1, cex=0.8))
abline(h=0)

with(irvin, stripchart(RUNS_VALUE ~ RUNNERS, vertical = TRUE, jitter = 0.2, xlab = "RUNNERS", method = "jitter", pch=1, cex=0.8))
abline(h=0)

with(sandy, stripchart(RUNS_VALUE ~ RUNNERS, vertical = TRUE, jitter = 0.2, xlab = "RUNNERS", method = "jitter", pch=1, cex=0.8))
abline(h=0)


# Use aggregate() to sum the total of 'RUNS_VALUE' for each base state

C_runs <- aggregate(cole$RUNS_VALUE, list(cole$RUNNERS), sum)
names(C_runs)[2] <- "RUNS"

I_runs <- aggregate(irvin$RUNS_VALUE, list(irvin$RUNNERS), sum)
names(I_runs)[2] <- "RUNS"

S_runs <- aggregate(sandy$RUNS_VALUE, list(sandy$RUNNERS), sum)
names(S_runs)[2] <- "RUNS"


# Use aggregate() to sum the total amount of times a pitcher is faced with each of the base states

C_PA <- aggregate(cole$RUNS_VALUE, list(cole$RUNNERS), length)
names(C_PA)[2] <- "PA"

I_PA <- aggregate(irvin$RUNS_VALUE, list(irvin$RUNNERS), length)
names(I_PA)[2] <- "PA"

S_PA <- aggregate(sandy$RUNS_VALUE, list(sandy$RUNNERS), length)
names(S_PA)[2] <- "PA"


# Use merge() to combine the previous 2 data frames
C <- merge(C_PA, C_runs)
C

I <- merge(I_PA, I_runs)
I

S <- merge(S_PA, S_runs)
S

# Use sum() to find the degree of change in run expectancy that a pitcher was on the mound for throughout the season
sum(C$RUNS) # -10.96 runs: Gerrit Cole
sum(I$RUNS) #   5.88 runs: Cole Irvin
sum(S$RUNS) # -28.49 runs: Sandy Alcantara

