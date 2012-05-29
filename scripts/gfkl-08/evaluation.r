# linear combinations

attribute_sets <- c("actors", "credits", "directors", "genres", "keywords")
colors         <- c("blue",   "green",   "cyan",      "red",    "yellow")


lc_result_colnames <- c("lambda", "MAE", "RMSE")
lc_ml1_result_table <- read.table("/home/mrg/gfkl/u1.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml2_result_table <- read.table("/home/mrg/gfkl/u2.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml3_result_table <- read.table("/home/mrg/gfkl/u3.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml4_result_table <- read.table("/home/mrg/gfkl/u4.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_ml5_result_table <- read.table("/home/mrg/gfkl/u5.lc-actors", sep="\t", header=FALSE, col.names=lc_result_colnames)
lc_result_table <- (lc_ml1_result_table + lc_ml2_result_table + lc_ml3_result_table + lc_ml4_result_table + lc_ml5_result_table) / 5



l    <- lc_result_table$lambda
mae  <- lc_result_table$MAE
rmse <- lc_result_table$RMSE

pdf(file = "lc-mae.pdf", width=7, height=6 ) 
#plot(l, mae, xlab="lambda", xlim=c(0,1), ylab="MAE", ylim=c(0.72 , 0.85), type="n", main="Linear combination: MAE")
plot(l, mae, xlab="lambda", xlim=c(0,1), ylab="MAE", ylim=c(0.72, 0.85), type="n")
for (i in 1:5) {
    lc_result_table <- read.table(paste("/home/mrg/gfkl/u1.lc-", attribute_sets[i], sep=""), sep="\t", header=FALSE, col.names=lc_result_colnames)
    for (fold in 2:5) {
        lc_result_table <- lc_result_table + read.table(paste("/home/mrg/gfkl/u", fold ,".lc-", attribute_sets[i], sep=""),
                                                        sep="\t", header=FALSE, col.names=lc_result_colnames)
    }
    lc_result_table <- lc_result_table / 5
    l    <- lc_result_table$lambda
    mae  <- lc_result_table$MAE
    lines(l, mae, col=colors[i], lwd=1, type="l")
    lines(l, mae, col=colors[i], lwd=1, type="p") 
}
axis(1, c(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0), tick=TRUE)
axis(2, c(0.725,0.775,0.825,0.875), labels=FALSE)
grid(lty="solid",col="grey")
legend("topright", title="Attributes", legend=attribute_sets, col=colors, lwd=2, lty=c("solid","solid","solid","solid","solid"), bg="white") 
dev.off()


pdf(file = "lc-rmse.pdf", width=7, height=6 ) 
#plot(l, rmse, xlab="lambda", xlim=c(0,1), ylab="RMSE", ylim=c(0.90, 1.15), type="n", main="Linear combination: RMSE")
plot(l, rmse, xlab="lambda", xlim=c(0,1), ylab="RMSE", ylim=c(0.95, 1.15), type="n")
for (i in 1:5) {
    lc_result_table <- read.table(paste("/home/mrg/gfkl/u1.lc-", attribute_sets[i], sep=""), sep="\t", header=FALSE, col.names=lc_result_colnames)
    for (fold in 2:5) {
        lc_result_table <- lc_result_table + read.table(paste("/home/mrg/gfkl/u", fold ,".lc-", attribute_sets[i], sep=""),
                                                        sep="\t", header=FALSE, col.names=lc_result_colnames)
    }
    lc_result_table <- lc_result_table / 5
    l    <- lc_result_table$lambda
    rmse  <- lc_result_table$RMSE
    lines(l, rmse, col=colors[i], lwd=1, type="l")
    lines(l, rmse, col=colors[i], lwd=1, type="p")
}
axis(1, c(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0), tick=TRUE)
#axis(2, c(0.725,0.775,0.825,0.875), labels=FALSE)
grid(lty="solid",col="grey")
legend("topright", title="Attributes", legend=attribute_sets, col=colors, lwd=2, lty=c("solid","solid","solid","solid","solid"), bg="white") 
dev.off()

