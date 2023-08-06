# Part 0: Set up the project

  # Step 1. Load the packages

  library(tidyverse)
  library(baseballr) # 'statcast_search_pitchers()' to get 2022 season pitch by pitch data
  

  # Step 2. Load your pitch by pitch Statcast data
  
  pdat <- read.csv()


  # Step 3. Order the pitches chronologically and filter the necessary columns
  
  matrix <- pdat %>% arrange(game_pk, at_bat_number, pitch_number) %>% 
                      select(away_team, away_score, home_team, home_score, game_pk, inning_topbot,
                             inning, on_1b, on_2b, on_3b, post_away_score, post_home_score, at_bat_number, 
                             pitch_number, des, batter, outs_when_up, player_name, pitch_name,
                             delta_run_exp, events)


# Part 1: Create RE24 matrix

  # Step 1: Add the 'RUNS_ROI' column to the 'matrix' data 
   # 'RUNS_ROI' calculates how many runs are scored for the rest of the inning from the moment of each pitch observation 
   # 'RUNS_ROI' is the value that will be averaged for each base-state to create the matrix


    # A. 'BAT_HOME_ID' column creates a unique identifier for the batting team of each half inning
    
    matrix$BAT_HOME_ID <- with(matrix, ifelse(inning_topbot == "Top", away_team, home_team))
    
    
    # B. 'HALF.INN' column creates a unique identifier for each half inning
    
    matrix$HALF.INN <- with(matrix, paste(game_pk, inning, BAT_HOME_ID))
    

    # C. 'RUNS' column contains the total runs in the game at the time of the pitch observation
    
    matrix$RUNS <- with(matrix, away_score + home_score)
    
    
    # D. 'RUNS_SCORED' column creates the number of runs scored as a result of the pitch observed in that row
    
    matrix$RUNS_SCORED <- with(matrix, ifelse(inning_topbot == "Top", (post_away_score - away_score), (post_home_score - home_score)))
    
    
    # E. Create 'RUNS_SCORED_START' data frame that tables the total amount of runs in the game at the start of each half inning with the half inning ID ('HALF.INN')
     # aggregate() is used to paste the first value in the 'RUNS' column for each 'HALF.INN' 
      
      RUNS_SCORED_START <- aggregate(matrix$RUNS, list(HALF.INN = matrix$HALF.INN), "[", 1)
    
    
    # F. Create 'RUNS_SCORED_INN' data frame that tables the amount of runs scored in each half inning with the half inning id 
     # aggregate() is used to sum the 'RUNS_SCORED' in each 'HALF.INN'
      
      RUNS_SCORED_INN <- aggregate(matrix$RUNS_SCORED, list(HALF.INN = matrix$HALF.INN), sum)
    
    
    # G. Create 'MAX' data frame that displays the total runs scored in the game to that point by both teams with the half inning id
      
      # i. Get the 'HALF.INN' identifier from previously created 'RUNS_SCORED_START' object
      MAX <- data.frame(HALF.INN = RUNS_SCORED_START$HALF.INN)
      
    
      # ii. Add the amount of runs scored in each half inning to the total amount of runs at the start of that half inning to get the max runs
        # This number tells us how many total runs in the game there will be by the end of the half inning for every pitch
      MAX$x <- RUNS_SCORED_INN$x + RUNS_SCORED_START$x
    
    
    # H. Merge 'MAX' with the original 'matrix' object
    
    matrix <- merge(matrix, MAX)
    
    
    # I. Rename the column currently titled 'x' from 'MAX' object
    
      # i. Get the number of the 'x' column so it can be called in the following step
      N <- ncol(matrix)
    
      # ii. Change the column name to 'MAX_RUNS'
      names(matrix)[N] <- "MAX_RUNS"
    
      
    # J. Get the difference between 'MAX_RUNS' and 'RUNS' for the 'RUNS_ROI' (Runs for the Rest Of the Inning) value
     # Remember 'RUNS' column contains the total amount of runs in the game at the time of a particular pitch observation
    
    matrix$RUNS_ROI <- with(matrix, MAX_RUNS - RUNS)
    
    
  # Step 2: Create the 'STATE' column, which will display the base-out state at the time of each pitch
   # 'STATE' examples >> bases EMPTY 0 outs, 'STATE' = "000 0" || bases LOADED 2 outs, 'STATE' =  "111 2"
      
    # A. Create a variable for each base that will display '0' if no runner is on that base and '1' if there is a runner on that base
        
    RUNNER1 <- ifelse(is.na(matrix$on_1b), 0, 1)
    RUNNER2 <- ifelse(is.na(matrix$on_2b), 0, 1)
    RUNNER3 <- ifelse(is.na(matrix$on_3b), 0, 1)
      
    # B. Create get.state() function, using the position of the base runners and the amount of outs as its input arguments
    
    get.state <- function(runner1, runner2, runner3, outs){
        runners <- paste(runner1, runner2, runner3, sep="")
        paste(runners, outs)
      }
    
    # C. Use 'RUNNER1', 'RUNNER2', 'RUNNER3', get.state() function, and 'outs_when_up' column to make the values for the 'STATE' column of the main 'matrix' object
    
    matrix$STATE <- get.state(RUNNER1, RUNNER2, RUNNER3, matrix$outs_when_up)
  
  # Step 3: Create the 'NEW_STATE' column that displays the base-out state directly following each pitch observation
  
    # A. Use coalesce() and lead() to create 'NEW_STATE' column, which is the 'STATE' directly following any particular pitch observation
    
    matrix$NEW_STATE <- coalesce(lead(matrix$STATE), "000 3")
    
    
    # B. Fix the 'NEW_STATE' column so that the last pitch observation of a half inning displays '000 3' instead of '000 0'
    
    matrix$NEW_STATE <- ifelse(
      matrix$STATE %in% c('000 2', '100 2', '010 2', '001 2', '110 2', '011 2', '101 2', '111 2') & matrix$NEW_STATE == '000 0',
      '000 3',
      matrix$NEW_STATE
    )
  
  
  # Step 4:  Filter the data
    
    # A. Filter out incomplete half innings
    
      # i. Unfortunately, missing values scattered throughout my particular scraped data frame made this task extremely difficult to execute perfectly
       # This was my closest attempt, if you have a data set without many missing values:
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
        
      # ii. Instead, I filtered out all 9th innings and beyond in a new data frame object called 'pmatrix'
      
      pmatrix <- matrix %>% filter(inning <= 8)
      
    
    # B. Subset 'pmatrix' again to filter out observations where 'STATE' and 'NEW_STATE' are the same or a run does not score 
    
    pmatrix <- subset(pmatrix, (STATE != NEW_STATE | RUNS_SCORED > 0))
  
  
  # Step 5: Create the 24 Base-Out States Run Expectancy Matrix
    
    # A. Create the data frame object 'RUNS', which will list the Run Expectancy values for each base-state
    
      # i. aggregate() is used to get the mean of 'RUNS_ROI' for each 'STATE'
      RUNS <- with(pmatrix, aggregate(RUNS_ROI, list(STATE), mean))
      
      # ii. substr() is used to isolate the last value from the 'STATE' ('000 [2]'), creating the 'Outs' column
      RUNS$Outs <- substr(RUNS$Group.1, 5, 5)
      
      # iii. Order the Run Expectancy data frame by 'Outs'
      RUNS <- RUNS[order(RUNS$Outs),]
    
    
    # B. Use matrix() to create 'RUNS.out' which will display 'RUNS' in the typical RE24 base-state out matrix format
      
      # i. Create the matrix and round values 
      RUNS.out <- matrix(round(RUNS$x, 2), 8, 3)
      
      # ii. Rename the rows and columns
      dimnames(RUNS.out)[[2]] <- c("0 outs", "1 out", "2 outs")
      dimnames(RUNS.out)[[1]] <- c("000", "001", "010", "011", "100", "101", "110", "111")
    
    
    # C. View the Run Expectancy matrix!
    
    view(RUNS.out)
  
  

# PART 2: Evaluate 3 players and create a league wide leader board
 # Reminder that the data is filtered to not include 9th inning or later, so starting pitchers make most sense to evaluate
 # Batters could be evaluated too if the 'player_name' column of your data set has the batter's name instead of the pitcher's
    
  
  # Step 1: Edit the 'pmatrix' data frame to include a 'RUNS_VALUE' column that calculates the change in run expectancy
  
    # A. Create 'RUNS_POTENTIAL' data frame to eventually merge with 'pmatrix' 
     # 'RUNS_POTENTIAL' values will contain the values to measure changes in run expectancy by base-out state, play by play
    
    RUNS_POTENTIAL <- matrix(c(RUNS$x, rep(0, 8)), 32, 1)
    dimnames(RUNS_POTENTIAL) [[1]] <- c(RUNS$Group.1, "000 3", "001 3", "010 3", "011 3", "100 3", "101 3", "110 3", "111 3")
    
    
    # B. 'RUNS_STATE' displays the amount of runs expected by the end of the half inning in the current observation's 'STATE'
    
    pmatrix$RUNS_STATE <- RUNS_POTENTIAL[pmatrix$STATE, ]
    
    
    # C. 'RUNS_NEW_STATE' displays the average amount of runs expected by the end of the half inning in the observation's following 'STATE'
    
    pmatrix$RUNS_NEW_STATE <- RUNS_POTENTIAL[pmatrix$NEW_STATE, ]
    
    
    # D. 'RUNS_VALUE' displays the difference between 'RUNS_NEW_STATE' and 'RUNS_STATE' plus the amount of 'RUNS_SCORED' in that observation to estimate the change in runs expectancy
    
    pmatrix$RUNS_VALUE <- pmatrix$RUNS_NEW_STATE - pmatrix$RUNS_STATE + pmatrix$RUNS_SCORED
    
  
  # Step 2: Evaluate players
  
    # A. Subset different pitchers from 'pmatrix'
    
    irvin <- subset(pmatrix, player_name == "Irvin, Cole")
    luis <- subset(pmatrix, player_name == "Severino, Luis")
    burnes <- subset(pmatrix, player_name == "Burnes, Corbin")
    
    
    # B. View the amount of times the pitcher faced each possible base state using table()
    
      # i. Use substr() on the 'STATE' column to isolate the runner portion of the 'STATE' value, which contains the position of each runner 
      irvin$RUNNERS <- substr(irvin$STATE, 1, 3)
      table(irvin$RUNNERS)
      
      luis$RUNNERS <- substr(luis$STATE, 1, 3)
      table(luis$RUNNERS)
      
      burnes$RUNNERS <- substr(burnes$STATE, 1, 3)
      table(burnes$RUNNERS)
    
    
    # C. Use stripchart() and abline() to create a chart showing the distribution of 'RUNS_VALUE' (expected runs) in each base-out state
    
    with(irvin, stripchart(RUNS_VALUE ~ RUNNERS, vertical = TRUE, jitter = 0.2, xlab = "RUNNERS", method = "jitter", pch=1, cex=0.8, main = player_name[1]))
    abline(h=0)
    
    with(luis, stripchart(RUNS_VALUE ~ RUNNERS, vertical = TRUE, jitter = 0.2, xlab = "RUNNERS", method = "jitter", pch=1, cex=0.8, main = player_name[1]))
    abline(h=0)
    
    with(burnes, stripchart(RUNS_VALUE ~ RUNNERS, vertical = TRUE, jitter = 0.2, xlab = "RUNNERS", method = "jitter", pch=1, cex=0.8, main = player_name[1]))
    abline(h=0)
    
    
    # D. Create a new data frame using aggregate() to sum the total 'RUNS_VALUE' by each base-out state and names() to rename the column 'RUNS'
    
    I_runs <- aggregate(irvin$RUNS_VALUE, list(irvin$RUNNERS), sum)
    names(I_runs)[2] <- "RUNS"
    
    L_runs <- aggregate(luis$RUNS_VALUE, list(luis$RUNNERS), sum)
    names(L_runs)[2] <- "RUNS"
    
    B_runs <- aggregate(burnes$RUNS_VALUE, list(burnes$RUNNERS), sum)
    names(B_runs)[2] <- "RUNS"
    
    
    # E. Create another data frame using aggregate() to sum the total amount of times a pitcher encounters each base-state and names() to rename the column 'PA'
    
    I_PA <- aggregate(irvin$RUNS_VALUE, list(irvin$RUNNERS), length)
    names(I_PA)[2] <- "PA"
    
    L_PA <- aggregate(luis$RUNS_VALUE, list(luis$RUNNERS), length)
    names(L_PA)[2] <- "PA"
    
    B_PA <- aggregate(burnes$RUNS_VALUE, list(burnes$RUNNERS), length)
    names(B_PA)[2] <- "PA"
    
    
    # F. Use merge() to combine the previous 2 data frames
    
    I <- merge(I_PA, I_runs)
    I
    
    L <- merge(L_PA, L_runs)
    L
    
    B <- merge(B_PA, B_runs)
    B
    
    
    # G. Use sum() to find the degree of change in run expectancy that a pitcher was on the mound for throughout the season
     # Multiply by -1 to get RE24
    
    -1 * sum(I$RUNS) #  -5.32: Cole Irvin
    -1 * sum(L$RUNS) #  13.99: Luis Severino
    -1 * sum(B$RUNS) #  18.87: Corbin Burnes
    
    
    # F. Divide the total amount of change in run expectancy by the number of batters faced to get a rate-type stat as opposed to a counting stat
     # Multiply by 700, an average amount of PAs or Batters Faced, and -1 to translate the values into a the familiar RE24 format
    
    700 * -1 * sum(I$RUNS)/nrow(irvin)  #  -4.91: Cole Irvin
    700 * -1 * sum(L$RUNS)/nrow(luis)   #  23.20: Luis Severino
    700 * -1 * sum(B$RUNS)/nrow(burnes) #  15.78: Corbin Burnes
  
  
  # Step 3: Create a standard RE24 leader board
    
    # A. Use aggregate() to sum the 'RUNS_VALUE' column by 'player_name'
    
    RE24 <- aggregate(RUNS_VALUE ~ player_name, data = pmatrix, FUN = function(x) -1 * round(sum(x),2))
    
    
    # B. Create 'freq' data frame to use as a count for the number of batters faced by each pitcher
    
    freq <- as.data.frame(table(pmatrix$player_name))
    
      # i. Rename the column so it can be merged with 'RE24'
      freq$player_name <- freq$Var1
      
      # ii. Merge 'freq' and 'RE24' by player_name
      RE24 <- merge(freq, RE24, by = "player_name", all = T)
      
    
    # C. Filter minimum batters faced
    
    RE24 <- RE24 %>% filter(Freq >=350) %>% arrange(desc(RUNS_VALUE))
    
    RE24$Var1 <- NULL
    
    
    # D. Change 'RUNS_VALUE' column name to 'RE24' and remove the old 'RUNS_VALUE' column
    
    RE24$RE24 <- RE24$RUNS_VALUE
    
    RE24$RUNS_VALUE <- NULL
    
    
    # E. View leader board
    
    view(RE24)

    
    
  # Step 4: Repeat similar steps to create a second leader board for the rated version of RE24
    
    RE24_adj <- aggregate(RUNS_VALUE ~ player_name, data = pmatrix, FUN = function(x) -1 * round(700 * sum(x) / length(x), 2))
    
    RE24_adj <- merge(freq, RE24_adj, by = "player_name", all = T)
    
    RE24_adj <- RE24_adj %>% filter(Freq >=350) %>% arrange(desc(RUNS_VALUE))
    
    RE24_adj$Var1 <- NULL
    
    RE24_adj$RE24_adj <- RE24_adj$RUNS_VALUE
    
    RE24_adj$RUNS_VALUE <- NULL
    
    view(RE24_adj)
    
