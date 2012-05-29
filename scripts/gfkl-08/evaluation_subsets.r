colors   <- c("blue",   "green",         "cyan",         "red")
methods  <- c("average", "coclustering", "item average", "user average")

coc_result_colnames <- c("k", "l", "rMAE", "MAE", "RMSE", "it", "maxit")
coc_sep             <- " "

percentage <- c(10, 20, 30, 40, 50, 60, 70, 80, 90)
coc_mae    <- c(0, 0, 0, 0, 0, 0, 0, 0, 0)
coc_rmse   <- c(0, 0, 0, 0, 0, 0, 0, 0, 0)
avg_mae    <- c(0.81706, 0.8134,  0.80688, 0.80416, 0.80112, 0.80066, 0.7984,  0.79712, 0.79524)
avg_rmse   <- c(1.0133,  1.01044, 1.00072, 0.99692, 0.99354, 0.99204, 0.98916, 0.98634, 0.98354)
uavg_mae   <- c(0.86068, 0.85942, 0.85142, 0.84944, 0.84716, 0.84538, 0.8429, 0.84064, 0.83646)
uavg_rmse  <- c(1.07236, 1.07142, 1.0611, 1.05926, 1.05684, 1.05488, 1.05176, 1.04892, 1.04424)


iavg_mae        <- c(0, 0, 0, 0, 0, 0, 0, 0, 0)
iavg_rmse       <- c(0, 0, 0, 0, 0, 0, 0, 0, 0)
# gavg_mae        <- c(0, 0, 0, 0, 0, 0, 0, 0, 0)
# gavg_rmse       <- c(0, 0, 0, 0, 0, 0, 0, 0, 0)


for (i in 1:9) {
    coc_result_table <- read.table(paste("/home/mrg/gfkl/random-3-3-100it-", i, "0-subset", sep=""), sep=coc_sep, header=FALSE, col.names=coc_result_colnames)
    coc_mae[i]  <- mean(coc_result_table$MAE)
    coc_rmse[i] <- mean(coc_result_table$RMSE)
    

}
pdf(file = "mae.pdf", width=7, height=6 ) 
plot(percentage, coc_mae, xlab="% of MovieLens", xlim=c(10,90), ylab="MAE", ylim=c(0.7, 0.9), type="n", main="MAE")
grid(lty="solid",col="grey")
lines(percentage, coc_mae, col="green", lwd=1, type="l") 
lines(percentage, coc_mae, col="green", lwd=1, type="p") 
lines(percentage, avg_mae, col="blue", lwd=1, type="l") 
lines(percentage, avg_mae, col="blue", lwd=1, type="p") 
lines(percentage, uavg_mae, col="red", lwd=1, type="l") 
lines(percentage, uavg_mae, col="red", lwd=1, type="p") 
legend("topright", legend=methods, col=colors, lwd=2, lty=c("solid","solid","solid","solid","solid"), bg="white") 
dev.off()


pdf(file = "rmse.pdf", width=7, height=6 ) 
plot(percentage, coc_rmse, xlab="% of MovieLens", xlim=c(10,90), ylab="RMSE", ylim=c(0.9, 1.1), type="n", main="RMSE")
grid(lty="solid",col="grey")
lines(percentage, coc_rmse, col="green", lwd=1, type="l") 
lines(percentage, coc_rmse, col="green", lwd=1, type="p") 
lines(percentage, avg_rmse, col="blue", lwd=1, type="l") 
lines(percentage, avg_rmse, col="blue", lwd=1, type="p") 
lines(percentage, uavg_rmse, col="red", lwd=1, type="l") 
lines(percentage, uavg_rmse, col="red", lwd=1, type="p") 
legend("topright", legend=methods, col=colors, lwd=2, lty=c("solid","solid","solid","solid","solid"), bg="white") 
dev.off()




