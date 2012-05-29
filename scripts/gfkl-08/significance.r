lc_result_colnames <- c("lambda", "MAE", "RMSE")


### Actors ###
lc_ml1_result_table <- read.table("/home/mrg/gfkl/u1.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml2_result_table <- read.table("/home/mrg/gfkl/u2.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml3_result_table <- read.table("/home/mrg/gfkl/u3.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml4_result_table <- read.table("/home/mrg/gfkl/u4.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml5_result_table <- read.table("/home/mrg/gfkl/u5.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
actor_mae_results <- cbind(
    lc_ml1_result_table$MAE,
    lc_ml2_result_table$MAE,
    lc_ml3_result_table$MAE,
    lc_ml4_result_table$MAE,
    lc_ml5_result_table$MAE
)
actor_rmse_results <- cbind(
    lc_ml1_result_table$RMSE,
    lc_ml2_result_table$RMSE,
    lc_ml3_result_table$RMSE,
    lc_ml4_result_table$RMSE,
    lc_ml5_result_table$RMSE
)

t.test(actor_mae_results[41,], actor_mae_results[31,], paired=TRUE, conf.level=0.99)
mean(actor_mae_results[41,])
mean(actor_mae_results[31,])

t.test(actor_rmse_results[41,], actor_rmse_results[31,], paired=TRUE, conf.level=0.99)
mean(actor_rmse_results[41,])
mean(actor_rmse_results[31,])


### Directors ###
lc_ml1_result_table <- read.table("/home/mrg/gfkl/u1.lc-directors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml2_result_table <- read.table("/home/mrg/gfkl/u2.lc-directors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml3_result_table <- read.table("/home/mrg/gfkl/u3.lc-directors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml4_result_table <- read.table("/home/mrg/gfkl/u4.lc-directors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml5_result_table <- read.table("/home/mrg/gfkl/u5.lc-directors", sep="\t", header=FALSE, col.names=lc_result_colnames)
director_mae_results <- cbind(
    lc_ml1_result_table$MAE,
    lc_ml2_result_table$MAE,
    lc_ml3_result_table$MAE,
    lc_ml4_result_table$MAE,
    lc_ml5_result_table$MAE
)
director_rmse_results <- cbind(
    lc_ml1_result_table$RMSE,
    lc_ml2_result_table$RMSE,
    lc_ml3_result_table$RMSE,
    lc_ml4_result_table$RMSE,
    lc_ml5_result_table$RMSE
)

t.test(director_mae_results[41,], director_mae_results[31,], paired=TRUE, conf.level=0.99)
mean(director_mae_results[41,])
mean(director_mae_results[31,])

t.test(director_rmse_results[41,], director_rmse_results[31,], paired=TRUE, conf.level=0.99)
mean(director_rmse_results[41,])
mean(director_rmse_results[31,])


### Genres ###
lc_ml1_result_table <- read.table("/home/mrg/gfkl/u1.lc-genres", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml2_result_table <- read.table("/home/mrg/gfkl/u2.lc-genres", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml3_result_table <- read.table("/home/mrg/gfkl/u3.lc-genres", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml4_result_table <- read.table("/home/mrg/gfkl/u4.lc-genres", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml5_result_table <- read.table("/home/mrg/gfkl/u5.lc-genres", sep="\t", header=FALSE, col.names=lc_result_colnames)
genre_mae_results <- cbind(
    lc_ml1_result_table$MAE,
    lc_ml2_result_table$MAE,
    lc_ml3_result_table$MAE,
    lc_ml4_result_table$MAE,
    lc_ml5_result_table$MAE
)
genre_rmse_results <- cbind(
    lc_ml1_result_table$RMSE,
    lc_ml2_result_table$RMSE,
    lc_ml3_result_table$RMSE,
    lc_ml4_result_table$RMSE,
    lc_ml5_result_table$RMSE
)

t.test(genre_mae_results[41,], genre_mae_results[31,], paired=TRUE, conf.level=0.99)
mean(genre_mae_results[41,])
mean(genre_mae_results[31,])

t.test(genre_rmse_results[41,], genre_rmse_results[31,], paired=TRUE, conf.level=0.99)
mean(genre_rmse_results[41,])
mean(genre_rmse_results[31,])


### Keywords ###
lc_ml1_result_table <- read.table("/home/mrg/gfkl/u1.lc-keywords", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml2_result_table <- read.table("/home/mrg/gfkl/u2.lc-keywords", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml3_result_table <- read.table("/home/mrg/gfkl/u3.lc-keywords", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml4_result_table <- read.table("/home/mrg/gfkl/u4.lc-keywords", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml5_result_table <- read.table("/home/mrg/gfkl/u5.lc-keywords", sep="\t", header=FALSE, col.names=lc_result_colnames)
keyword_mae_results <- cbind(
    lc_ml1_result_table$MAE,
    lc_ml2_result_table$MAE,
    lc_ml3_result_table$MAE,
    lc_ml4_result_table$MAE,
    lc_ml5_result_table$MAE
)
keyword_rmse_results <- cbind(
    lc_ml1_result_table$RMSE,
    lc_ml2_result_table$RMSE,
    lc_ml3_result_table$RMSE,
    lc_ml4_result_table$RMSE,
    lc_ml5_result_table$RMSE
)

t.test(keyword_mae_results[41,], keyword_mae_results[31,], paired=TRUE, conf.level=0.99)
mean(keyword_mae_results[41,])
mean(keyword_mae_results[31,])

t.test(keyword_rmse_results[41,], keyword_rmse_results[31,], paired=TRUE, conf.level=0.99)
mean(keyword_rmse_results[41,])
mean(keyword_rmse_results[31,])


### Credits ###
lc_ml1_result_table <- read.table("/home/mrg/gfkl/u1.lc-credits", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml2_result_table <- read.table("/home/mrg/gfkl/u2.lc-credits", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml3_result_table <- read.table("/home/mrg/gfkl/u3.lc-credits", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml4_result_table <- read.table("/home/mrg/gfkl/u4.lc-credits", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml5_result_table <- read.table("/home/mrg/gfkl/u5.lc-credits", sep="\t", header=FALSE, col.names=lc_result_colnames)
credit_mae_results <- cbind(
    lc_ml1_result_table$MAE,
    lc_ml2_result_table$MAE,
    lc_ml3_result_table$MAE,
    lc_ml4_result_table$MAE,
    lc_ml5_result_table$MAE
)
credit_rmse_results <- cbind(
    lc_ml1_result_table$RMSE,
    lc_ml2_result_table$RMSE,
    lc_ml3_result_table$RMSE,
    lc_ml4_result_table$RMSE,
    lc_ml5_result_table$RMSE
)

t.test(credit_mae_results[41,], credit_mae_results[31,], paired=TRUE, conf.level=0.99)
mean(credit_mae_results[41,])
mean(credit_mae_results[31,])

t.test(credit_rmse_results[41,], credit_rmse_results[31,], paired=TRUE, conf.level=0.99)
mean(credit_rmse_results[41,])
mean(credit_rmse_results[31,])


### Comparisons between attribute sets ###
## credits on RMSE vs. all
mean(credit_rmse_results[31,])
mean(actor_rmse_results[31,])
mean(director_rmse_results[31,])
mean(genre_rmse_results[31,])
mean(keyword_rmse_results[31,])
t.test(actor_rmse_results[31,], credit_rmse_results[31,], paired=TRUE, conf.level=0.99)
t.test(director_rmse_results[31,], credit_rmse_results[31,], paired=TRUE, conf.level=0.99)
t.test(genre_rmse_results[31,], credit_rmse_results[31,], paired=TRUE, conf.level=0.99)
t.test(keyword_rmse_results[31,], credit_rmse_results[31,], paired=TRUE, conf.level=0.99)
## credits on MAE vs. all
mean(credit_mae_results[31,])
mean(actor_mae_results[31,])
mean(director_mae_results[31,])
mean(genre_mae_results[31,])
mean(keyword_mae_results[31,])
t.test(actor_mae_results[31,],    credit_mae_results[31,], paired=TRUE, conf.level=0.99)
t.test(director_mae_results[31,], credit_mae_results[31,], paired=TRUE, conf.level=0.99)
t.test(genre_mae_results[31,],    credit_mae_results[31,], paired=TRUE, conf.level=0.99)
t.test(keyword_mae_results[31,],  credit_mae_results[31,], paired=TRUE, conf.level=0.99)
