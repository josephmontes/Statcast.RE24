In this code, I use Statcast data to create a Run Expectancy Matrix
.
'Analyzing Baseball Data with R' helped me create this, but they used Retrosheet data in their example
.
There are 2 parts to the code in this project
.
In the first part, the run expectancy matrix is made using pitch by pitch Statcast data
.
In the second part, 3 pitchers are evaluated in terms of the change in run expectancy that occured while he was pitching.
.

Statcast data scraped from baseballr::statcast_search_pitchers()
.
Unfortunately, there were a lot of missing values scattered across multiple important variables in my data
