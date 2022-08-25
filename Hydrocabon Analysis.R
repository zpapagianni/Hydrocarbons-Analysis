#Hydrocarbon mixture analysis and predictions
# 27/03/2022
# Load relevant packages -------------------------------------------------------
library(dplyr)
library(irlba)
library(ggplot2)
library(ggpubr)
library(glmnet)
library(tidyverse)
library(reshape2)
library(randomForest)
library(e1071)
library(caret)
library(Metrics)
library(tree)
library(pls)
library(gridExtra)
library(corrplot)
library(Hmisc)
library(PerformanceAnalytics)
library(gbm)

#Set seed to replicate results
set.seed(9)

#Functions --------------------------------------------------------------------
#This formats a correlation matrix into a table with 4 columns containing
#row names,column names, the correlation coefficients,the p-values of the correlations
#source(http://www.sthda.com/english/wiki/correlation-matrix-formatting-and-visualization)
flattenCorrMatrix <- function(cormat, pmat) {
  ut <- upper.tri(cormat)
  data.frame(
    row = rownames(cormat)[row(cormat)[ut]],
    column = rownames(cormat)[col(cormat)[ut]],
    cor  =(cormat)[ut],
    p = pmat[ut]
  )
}

# Load data --------------------------------------------------------------------
hydro<- read_csv("data.csv") 

#Clean the data --------------------------------------------------------------------
# Omit date column 
hydro<-hydro%>% select(-date)
#Type of each column 
str(hydro)
#Convert catalyst to factor
hydro$catalyst<-as.factor(hydro$catalyst)

#---------------------------------------------------------------------------------
#Process the data --------------------------------------------------------------------
#Summary statistics.
summary(hydro)
hydro %>%select(catalyst,temperature) %>% group_by(catalyst) %>% 
  summarise(mean=mean(temperature),median=median(temperature),var=var(temperature),
            max=max(temperature),min=min(temperature))

hydro %>%select(catalyst,through_time) %>% group_by(catalyst) %>% 
  summarise(mean=mean(through_time),median=median(through_time),var=var(through_time),
            max=max(through_time),min=min(through_time))

#Visualize data --------------------------------------------------------------------
##Through time and Temperature
boxplot_temp<-ggplot(hydro,aes(x=catalyst,y=temperature,color=temperature))+
  geom_boxplot(fill = "#4271AE", colour = "#1F3552",alpha = 0.8)+
  scale_y_continuous(name = "Temperature in\n Fahrenheit",limits=c(400, 1000)) +
  scale_x_discrete(name = "Catalyst")+
  theme_bw()+ ggtitle("Summary of Temperature")+
  theme(plot.title = element_text(size=10),
        text = element_text(size=9))
boxplot_temp

boxplot_time<-ggplot(hydro, aes(x=catalyst, y=through_time, color=through_time)) +
  geom_boxplot()+
  geom_boxplot(fill = "#4271AE", colour = "#1F3552",alpha = 0.8)+
  scale_y_continuous(name = "Summary of Residence Time") +
  scale_x_discrete(name = "Catalyst")+
  theme_bw()+
  labs(title = "Mean residence time")+
  theme(plot.title = element_text(size=10),
        text = element_text(size=9))
boxplot_time

##Feed hydrocarbon mixtures
##Feed Yield boxplots --------------------------------------------------
#Data frame of feed mixtures
feed<-hydro %>%select(starts_with('feed'))
#Box Plot
boxplot_feed<-ggplot(stack(feed), aes(x = ind, y = values)) +
  geom_boxplot()+ 
  theme_bw()+
  geom_boxplot(fill = "#4271AE", colour = "#1F3552",alpha = 0.8)+
  scale_y_continuous(name = "Proportion of overall mass") +
  scale_x_discrete(name = "Density Intervals",labels=as.character(seq(1:20)))+
  ggtitle("Feed composition mixture per density interval")
boxplot_feed

# Histogram
#Create dataframe for histogram and selected intervals
hist_feed.data<-feed %>% 
  select(feed_fraction_1,feed_fraction_5,feed_fraction_10,feed_fraction_15,feed_fraction_20) %>% 
  melt(measure.vars = c('feed_fraction_1','feed_fraction_5','feed_fraction_10','feed_fraction_15','feed_fraction_20'))   
#Mean per interval
mu_feed<- hist_feed.data %>% group_by(variable) %>% 
  summarise(mean=mean(value))

hist_feed<-ggplot(hist_feed.data, aes(x=value,color=variable)) + 
  geom_density(position = "identity", alpha=0.2)+
  geom_vline(data=mu_feed,aes(xintercept=mean,color=variable),
             linetype="dashed", size=1)+
  theme_bw()+theme(legend.position='bottom')+
  theme(legend.position = c(0.7, 0.6),
        legend.title = element_text(size=8,face="bold"),
        legend.text = element_text(size=8),
        plot.title = element_text(size=9),
        text = element_text(size=9))+
  xlab('Proportion of Mixture ') +  
  ggtitle('Proportion of Feed Hydrocarbon Mixture\n for selected intervals')+
  labs(colour = "Density interval")+scale_color_brewer(palette="Set1")
hist_feed

grid.arrange(boxplot_temp,boxplot_time,hist_feed,ncol=3)

##Plot distribution for target variables interval 13,14 and 15.
feed %>% select(feed_fraction_13,feed_fraction_14,feed_fraction_15) %>% stack %>% 
  ggplot(aes(x = ind, y = values)) +
  geom_boxplot()+
  theme_bw()+
  geom_boxplot(fill = "#4271AE", colour = "#1F3552",alpha = 0.8)+
  scale_y_continuous(name = "Proportion of overall mass") +
  scale_x_discrete(name = "Density Intervals",labels=abbreviate)

##Effluent hydrocarbon mixtures --------------------------------------------------
#Create dataframe
out<-hydro %>%select(starts_with('out'))
##Boxplots
ggplot(stack(out), aes(x = ind, y = values)) +
  geom_boxplot()+
  theme_bw()+
  geom_boxplot(fill = "#4271AE", colour = "#1F3552",alpha = 0.8)+
  scale_y_continuous(name = "Proportion of overall mass") +
  scale_x_discrete(name = "Density Intervals",labels=as.character(seq(1:20)))+
  ggtitle("Effluent composition mixture per density interval")

#Distributions of effluents composition in interval 13,14 and 15.
#Boxplot
out %>% select(out_fraction_13,out_fraction_14,out_fraction_15) %>% stack %>% 
  ggplot(aes(x = ind, y = values)) +
  geom_boxplot()+theme_bw()+
  geom_boxplot(fill = "#4271AE", colour = "#1F3552",alpha = 0.8)+
  scale_y_continuous(name = "Proportion of overall mass") +
  scale_x_discrete(name = "Density Intervals")

#Histograms
ggplot(hydro, aes(x=out_fraction_13)) + 
  geom_histogram(color="#1F3552", fill="#4271AE",alpha=0.7)+
  geom_density()+
  geom_vline(aes(xintercept=mean(out_fraction_13)),color="#1F3552", linetype="dashed", size=1)+
  ggtitle("Histogram of effluent mixture in interval 13")+
  xlab("Proportion of effluent mixture")+
  theme_bw()

ggplot(hydro, aes(x=out_fraction_14)) + 
  geom_histogram(color="#1F3552", fill="#4271AE",alpha=0.7)+
  geom_density()+
  geom_vline(aes(xintercept=mean(out_fraction_13)),color="#1F3552", linetype="dashed", size=1)+
  ggtitle("Histogram of effluent mixture in interval 14")+
  xlab("Proportion of effluent mixture")+
  theme_bw()

ggplot(hydro, aes(x=out_fraction_15)) + geom_density(aes(x=out_fraction_15))+
  geom_histogram(color="#1F3552", fill="#4271AE",alpha=0.7)+
  geom_vline(aes(xintercept=mean(out_fraction_15)),color="#1F3552", linetype="dashed", size=1)+
  ggtitle("Histogram of effluent mixture in interval 15")+
  xlab("Proportion of effluent mixture")+
  theme_bw()

#Combined Histogram for effluent mixtures
#Create data for Histogram
hist_out.data<-out %>% 
  select(out_fraction_1,out_fraction_5,out_fraction_10,out_fraction_15,out_fraction_20) %>% 
  melt(measure.vars = c('out_fraction_1','out_fraction_5','out_fraction_10','out_fraction_15','out_fraction_20'))   

#Mean per interval
mu_out<- hist_out.data %>% group_by(variable) %>% 
  summarise(mean=mean(value))
#Histogram
hist_out<-ggplot(hist_out.data, aes(x=value,color=variable)) + 
  geom_density(position = "identity", alpha=0.2)+
  geom_vline(data=mu_out,aes(xintercept=mean,color=variable),
             linetype="dashed", size=1)+
  theme_bw()+
  theme(legend.position = c(0.8, 0.6),
        legend.title = element_text(size=8,face="bold"),
        legend.text = element_text(size=8),
        plot.title = element_text(size=9),
        text = element_text(size=9))+
  xlab('Proportion of Mixture ') +  
  ggtitle('Proportion of Feed Hydrocarbon Mixture for selected intervals')+
  labs(colour = "Density interval")+
  scale_color_brewer(palette="Set1")

hist_out

#Combined Histogram for response variables
#Create data for Histogram
hist_response<-out %>% select(out_fraction_13,out_fraction_14,out_fraction_15) %>% 
  melt(measure.vars = c('out_fraction_13','out_fraction_14','out_fraction_15'))
#Find mean
mu_response <-hist_response %>%group_by(variable) %>% summarise(mean=mean(value))
#Creat density plot
hist_response<- ggplot(hist_response.data, aes(x=value,color=variable)) + 
  geom_density(position = "identity", alpha=0.2)+
  geom_vline(data=mu_response,aes(xintercept=mean,color=variable),
             linetype="dashed", size=1)+
  theme_bw()+
  theme(legend.position = c(0.7, 0.6),
        legend.title = element_text(size=8,face="bold"),
        legend.text = element_text(size=8),
        text = element_text(size=9))+
  xlab('Proportion of Mixture ') +  
  ggtitle('Response Variables')+
  labs(colour = "Density interval")+
  scale_color_brewer(palette="Set1")
hist_response

#Save plots
grid.arrange(hist_out,hist_response,ncol=2)
png("Distribution of effluents.png",width =760 ,height=370)
grid.arrange(hist_out,hist_response,ncol=2)
dev.off()

#Create response variable ----------------------------------------------------------------------------------------------------
df<-hydro %>% 
  mutate(sum_int = out_fraction_13+out_fraction_14+out_fraction_15)
#Scatter plot temperature, response variables and sum.
out_temp<-df %>% 
  select(temperature,out_fraction_13,out_fraction_14,out_fraction_15,sum_int) %>% 
  pivot_longer(-temperature, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x=temperature,y=value , colour = variable)) + 
  geom_point(alpha=0.4)+
  geom_smooth(method = "loess",se=F)+
  theme_bw()+
  theme(legend.position = c(0.7, 0.8),
        legend.title = element_text(size=8,face="bold"),
        legend.text = element_text(size=8),
        text = element_text(size=9))+
  xlab("Temperature(°F)") +  
  ylab('Proportion of Mixture')+
  ggtitle('Temperature and Mixture Proportion')+
  labs(colour = "Density interval")+
  scale_color_brewer(palette="Set1")
out_temp 

#Scatter plot time, response variables and sum.
out_time<-df %>% 
  select(through_time,out_fraction_13,out_fraction_14,out_fraction_15,sum_int) %>% 
  pivot_longer(-through_time, names_to = "variable", values_to = "value") %>% 
  ggplot(aes(x=through_time,y=value, colour = variable)) + 
  geom_point(alpha=0.4)+
  geom_smooth(method = "loess",se=F)+
  theme_bw()+
  theme(legend.position = c(0.7, 0.8),
        legend.title = element_text(size=8,face="bold"),
        legend.text = element_text(size=8),
        text = element_text(size=9))+
  xlab("Residence Time(hours)") +  
  ylab('Proportion of Mixture')+
  ggtitle('Residence Time and Mixture Proportion')+
  labs(colour = "Density interval")+
  scale_color_brewer(palette="Set1")
out_time

#Box plot catalyst, response variables and sum.
#Create Data frame 
out_catalyst.data<-df %>% 
  select(catalyst,out_fraction_13,out_fraction_14,out_fraction_15) %>% 
  pivot_longer(-catalyst, names_to = "variable", values_to = "value")
#Box plots
out_catalyst<-ggplot(out_catalyst.data,aes(x=variable,y=value,color=variable))+
  geom_boxplot()+facet_grid(~catalyst)+
  theme_bw()+
  theme(text = element_text(size=12),strip.text.x = element_text(size = 12),legend.position = c(0.9, 0.8))+
  scale_x_discrete(name = "Density Intervals",label=c('13','14','15'))+
  ggtitle('Mixture Proportion for Response Variables for each catalyst ')+
  labs(colour = "Density interval")+
  scale_color_brewer(palette="Set1")
out_catalyst

png("outcatalyst.png",width =850 ,height=340)
out_catalyst
dev.off()
grid.arrange(out_temp,out_time,ncol=2)

#----------------------------------------------------------------------------------------------------------
#Correlation matrices--------------------------------------------------------------------------------------
#Prepare data
features<-df[,2:23]
features<-cbind(features,sum=df$sum_int)
colnames(features)[3:22]<-as.character(seq(1:20))
colnames(features)[1]<-'temp'
colnames(features)[2]<-'time'

#Find correlation matrix
cor.features<-cor(features)

#Visualize correlations
plot.cor<-corrplot(cor.features,  method = "color")

#Find the significance of correlations between variables
matrix_feed<-rcorr(as.matrix(features))

#Flatten matrix for visualization
cor_matrix<-flattenCorrMatrix(matrix_feed$r, matrix_feed$P)
cor_matrix[,3:4]<-round(cor_matrix[,3:4],2)

#Create table with significant correlations
sign.cor<-rbind(cor_matrix[232:233,],cor_matrix[243:249,])

#Save table
png("correlation.png")
p<-tableGrob(sign.cor)
grid.arrange(p)
dev.off()

#Create bar chart for Important features
cor.imp<-cor_matrix %>% 
  #Filter response variable
  filter(column=='sum') %>% 
  ggplot(aes(x = abs(cor),
             y = forcats::fct_reorder(.f = row, .x = abs(cor)),fill =abs(cor))) +
  geom_col() +
  ggtitle('Correlation Matix') +
  xlab("Coefficients")+
  ylab(NULL)+
  theme_bw()+
  scale_color_brewer("Set1")+
  theme(legend.position = "none")

#----------------------------------------------------------------------------------------------------------
#Prepare Training And Test Data----------------------------------------------------------------------------
#Create response variable
hydro<-hydro %>% 
  mutate(sum_int = out_fraction_13+out_fraction_14+out_fraction_15)
#Define data and remove features we don't need
data<-hydro %>% select(-starts_with('out'))
#Define training indexes
trainingIndex <- sample(1:nrow(data), 0.8*nrow(data)) # indices for 80% training data
#Define training data
data.train<-data[trainingIndex, ]
#Define testing data
data.test <- data[-trainingIndex, ]

##Regularization----------------------------------------------------------------------------
#Create observations and target variable for training data
x.train<- data.train %>% select(-sum_int) %>% data.matrix
y.train<- data.train$sum_int# training data
#Create observations and target variable for testing data
x.test<-data.test %>% select(-sum_int) %>% data.matrix
y.test<- data.test$sum_int

#Create empty list used to save fits
list.of.fits <- list()
#number of iterations
it<-100
## We are testing alpha = i/100.
for (i in 0:it) {
  ## Create variable name
  fit.name <- paste0("alpha", i/it)
  ## Fit a model and store it in a list 
  list.of.fits[[fit.name]] <-
    cv.glmnet(x.train, y.train, type.measure="mse", alpha=i/it, 
              family="gaussian")
}
## Find which alpha results in the min MSE
reg.results <- data.frame()
for (i in 0:it) {
  fit.name <- paste0("alpha", i/it)
  ## Use each model to calculate predictions given the Testing dataset
  predicted <- 
    predict(list.of.fits[[fit.name]], 
            s=list.of.fits[[fit.name]]$lambda.min, newx=x.test)
  
  ## Calculate the Mean Squared Error
  mse <- mean((y.test - predicted)^2)
  
  ## Store the results
  temp <- data.frame(alpha=i/it, mse=mse, fit.name=fit.name)
  reg.results <- rbind(reg.results, temp)
}
#See results
reg.results
#Plot mse and alpha value 
ggplot(reg.results,aes(x=alpha,y=mse))+
  theme_bw()+
  geom_line(color="#1F3552")+
  ggtitle("MSE for different alpha values")+
  ylab("MSE")

#Save best alpha
best.alpha=reg.results$alpha[which.min(reg.results$mse)]
#Use the value to create the best model
reg.model<-cv.glmnet(x.train, y.train, type.measure="mse", 
                       alpha=best.alpha, 
                       family="gaussian")

#Find non zero coefficients
coef.reg <- coef(reg.model)
#Create data frame
imp.coef_reg<-data.frame(coef=coef.reg[coef.reg[,1]!=0,])
imp.coef_reg<-rownames_to_column(imp.coef_reg, "variables")
imp.coef_reg$variables<-str_replace(imp.coef_reg$variables,"feed_fraction_", "")

#Plot most important variables
reg_coef<-imp.coef_reg %>%
  filter(variables!=c("(Intercept)")) %>% 
  ggplot(aes(x = abs(coef),y = forcats::fct_reorder(.f = variables, 
                                    .x = abs(coef)),fill =abs(coef))) +
  geom_col() +
  ggtitle('Elastic Net Regression') +
  xlab("Coefficients")+
  ylab(NULL)+
  theme_bw()+ 
  scale_color_brewer("Set1")+
  theme(legend.position = "none")
reg_coef

png("coefficients.png")
p<-tableGrob(imp.coef_reg)
grid.arrange(p)
dev.off()

#use fitted best model to make predictions
reg.predicted <- predict(reg.model,alpha = best.alpha, newx = x.test)

#Performance metrics
#find SST and SSE
reg.sst <- sum((y.test - mean(y.test))^2)
reg.sse <- sum((reg.predicted - y.test)^2)
reg.mse <- mean((y.test - reg.predicted)^2)
#find R-Squared
reg.rsq <- 1 - reg.sse/reg.sst

#Data frame with performance metrics
reg.perf=data.frame(MSE=reg.mse, 
                    Rsquare=reg.rsq*100,
                    RMSE=sqrt(reg.mse))

#Lasso model----------------------------------------------------------------------------
#Create vector with lambdas
lambdas <- 10^seq(2, -3, by = -.1)
# Setting alpha = 1 implements lasso regression
lasso_reg <- cv.glmnet(x.train, y.train, alpha = 1, lambda = lambdas, standardize = TRUE, nfolds = 10)
# Best model
lambda_best <- lasso_reg$lambda.min 
lasso_model <- glmnet(x.train, y.train, alpha = 1, lambda = lambda_best, standardize = TRUE)

#Save coefficients
coef.lasso<- coef(lasso_model)
#Compare coefficients with Lasso model
cbind(coef.reg, coef.lasso)

#Create data frame
imp.coef_las<-data.frame(coef=coef.lasso[coef.lasso[,1]!=0,])
#Convert row names to column
imp.coef_las<-rownames_to_column(imp.coef_las, "variables")
imp.coef_las$variables<-str_replace(imp.coef_las$variables,"feed_fraction_", "")

#Plot most important variables
las_coef<-imp.coef_las %>%
  filter(variables!=c("(Intercept)")) %>% 
  ggplot(aes(x = abs(coef),y = forcats::fct_reorder(.f = variables, 
                                                    .x = abs(coef)),fill =abs(coef))) +
  geom_col() +
  ggtitle('Lasso Regression') +
  xlab("Coefficients")+
  ylab(NULL)+
  theme_bw()+
  scale_color_brewer("Set1")+
  theme(legend.position = "none")
las_coef

#Prediction using model
lasso.pred<-predict(lasso_reg,lambda = lambda_best, newx = x.test)
#Performance metrics
#find SST and SSE
lasso.sse <- sum((lasso.pred - y.test)^2)
lasso.mse <- mean((y.test - lasso.pred)^2)
#find R-Squared
lasso.rsq <- 1 - lasso.sse/reg.sst

#Data frame with performance metrics
lasso.perf<-data.frame(MSE=lasso.mse, 
                       Rsquare=lasso.rsq*100,
                       RMSE=sqrt(lasso.mse))


##Random forest -----------------------------------------------------------------------------------------------------------------------
#Evaluate different values for ntree.
#Create empty list for saving performance and number of trees
modellist <- data.frame()
#Loop through different number of trees
for (ntree in c(500,1000, 1500, 2000, 2500)) {
  set.seed(1)
  key <- toString(ntree)
  fit <- randomForest(sum_int ~ ., 
                      data=data,
                      ntree=ntree,
                      importance=TRUE,
                      xtest   = data.frame(x.test),
                      ytest   = y.test)
  modellist<- rbind(modellist,c(ntree,sqrt(fit$mse[which.min(fit$mse)])))
}
#Format column names
colnames(modellist)<-c('ntrees','MSE')

#Find best number of trees
best.ntree<-modellist[which.min(modellist$MSE),1]

#Train best model
rf.model0 <- randomForest(sum_int ~ ., 
                          data=data,
                          ntree=best.ntree,
                          importance=TRUE,
                          xtest   = data.frame(x.test),
                          ytest   = y.test)
rf.model0
#Prediction accuracy
y.pred0<-rf.model0$test$predicted
mean<-sum(y.test)/length(y.test)
rf.mse0<-sum((y.test-y.pred0)^2)/length(y.test)
rf.r20<-(1-(rf.mse0/sum((y.test-mean)^2)/length(y.test)))*100
#Create data with performance analytics
rf.perf0<-data.frame(MSE=rf.mse0,
                     Rsquare=rf.r20,
                    #find RMSE of best model
                    RMSE=sqrt(rf.model0$mse[which.min(rf.model0$mse)]) )

# Get variable importance from the model fit
ImpData <- as.data.frame(importance(rf.model0))
ImpData$Var.Names <- row.names(ImpData)

ggplot(ImpData, aes(x=Var.Names, y=`%IncMSE`)) +
  geom_segment( aes(x=Var.Names, xend=Var.Names, y=0, yend=`%IncMSE`), color="skyblue") +
  geom_point(aes(size = IncNodePurity), color="blue", alpha=0.6) +
  theme_light() +
  coord_flip() +
  theme(
    legend.position="bottom",
    panel.grid.major.y = element_blank(),
    panel.border = element_blank(),
    axis.ticks.y = element_blank()
  )

ImpData$Var.Names<-str_replace(ImpData$Var.Names,"feed_fraction_", "")

#Plot most important variables
rf_coef0<-ImpData %>%
  ggplot(aes(x = `%IncMSE`,y = forcats::fct_reorder(.f = Var.Names, 
                                                    .x = `%IncMSE`),fill =`%IncMSE`)) +
  geom_col() +
  ggtitle('Random Forest') +
  xlab("%IncMSE")+
  ylab(NULL)+
  theme_bw()+
  scale_color_brewer("Set1")+
  theme(legend.position = "none")
rf_coef0

#Extract important features to train new model
imp_var<-ImpData[which(abs(ImpData$`%IncMSE`)>10),]

png("rf_imp_var.png")
p<-tableGrob(imp_var)
grid.arrange(p)
dev.off()

#Create new data frame with important variables
dat.imp<-data %>% select(rownames(imp_var),sum_int)
#Testing data
x.test.imp<-data.test %>% select(rownames(imp_var))
#Find optimum number of trees
modellist1 <- data.frame()
for (ntree in c(500,1000, 1500, 2000, 2500)) {
  set.seed(1)
  key <- toString(ntree)
  fit <- randomForest(sum_int ~ ., 
                      data=dat.imp,
                      ntree=ntree,
                      importance=TRUE,
                      xtest   =  data.frame(x.test.imp),
                      ytest   = y.test)
  modellist1<- rbind(modellist,c(ntree,sqrt(fit$mse[which.min(fit$mse)])))
}
colnames(modellist1)<-c('ntrees','MSE')
best.ntree1<-modellist1[which.min(modellist1$MSE),1]
#Train best model
rf.model1 <- randomForest(sum_int ~ ., 
                          data=dat.imp,
                          ntree=best.ntree1,
                          importance=TRUE,
                          xtest   = data.frame(x.test.imp),
                          ytest   = y.test)
rf.model1

# Get variable importance from the model fit
ImpData1<- as.data.frame(importance(rf.model1))
ImpData1$Var.Names <- row.names(ImpData1)
ImpData1$Var.Names<-str_replace(ImpData1$Var.Names,"feed_fraction_", "")

#Plot most important variables
rf_coef1<-ImpData1 %>%
  ggplot(aes(x = `%IncMSE`,y = forcats::fct_reorder(.f = Var.Names, 
                                                    .x = `%IncMSE`),fill =`%IncMSE`)) +
  geom_col() +
  ggtitle('Random Forest(Reducted)') +
  xlab("%IncMSE")+
  ylab(NULL)+
  theme_bw()+
  scale_color_brewer("Set1")+
  theme(legend.position = "none")
rf_coef1

#Prediction accuracy
y.pred1<-rf.model1$test$predicted
rf.mse1<-sum((y.test-y.pred1)^2)/length(y.test)
rf.r21<-(1-(rf.mse1/sum((y.test-mean)^2)/length(y.test)))*100
rf.perf1<-data.frame(MSE=rf.mse1, 
                     Rsquare=rf.r21,
                     RMSE=sqrt(rf.model1$mse[which.min(rf.model1$mse)]))

png("rf_perf.png")
p<-tableGrob(rf.perf)
grid.arrange(p)
dev.off()

#Gradient Boosting Machine-----------------------------------------------------------------------------------------------------------------------
#Fit model
boost_feed <- gbm(sum_int ~ ., data=data.train,
                  distribution = "gaussian", 
                  n.trees = 2000, 
                  shrinkage = 0.01,
                  interaction.depth = 4,
                  cv.folds = 10)
#Summary
summary(boost_feed)
#Find the number of trees that results to the minimum square error
gbm.perf(boost_feed,method = 'cv')
which.min(boost_feed$cv.error)

#Compute predictions using the optimum number of trees
boost_pred <- predict(
  boost_feed, 
  newdata = data.test,ntrees=which.min(boost_feed$cv.error))

#Performance metrics
bg.mse<-sum((data.test$sum_int-boost_pred)^2)/length(data.test$sum_int)
bg.r2<-(1-(rf.mse0/sum((data.test$sum_int-mean)^2)/length(data.test$sum_int)))*100
bg.perf<-data.frame(MSE=bg.mse,
                    Rsquare=bg.r2,
                    RMSE= sqrt(mean((boost_pred - data.test$sum_int)^2)))

#Find influential variables 
FeedEffects <- as_tibble(summary.gbm(boost_feed,plotit = FALSE))
#Format variables names
FeedEffects$var<-str_replace(FeedEffects$var,"feed_fraction_", "")

#Plot important variables 
boost_coef<-FeedEffects %>% 
  # plot these data using columns
  ggplot(aes(x = forcats::fct_reorder(.f = var, 
                                      .x = rel.inf), 
             y = rel.inf, 
             fill = rel.inf)) +
  geom_col() +
  # flip
  coord_flip() +
  # format
  theme_bw() +
  scale_color_brewer("Set1")+
  theme(legend.position = "none")+
  xlab('') +
  ylab('Relative Influence') +
  ggtitle("Gradient Boosting Machine")
boost_coef

# Create Data frame with predicted and actual values
boost.results<-data.frame(actual=data.test$sum_int,predicted=boost_pred)

# plot predicted v actual
ggplot(boost.results) +
  geom_point(aes(y = predicted, 
                 x = actual, 
                 color = predicted - actual), alpha = 0.7) +
  # add theme
  theme_bw() +
  # strip text
  theme(axis.title = element_text()) + 
  # add axes/legend titles
  scale_color_continuous(name = "Predicted - Actual") +
  ylab('Predicted Effluent Mixture') +
  xlab('Actual Effluent Mixture') +
  ggtitle('Predicted vs Actual') 

##Partial Least Squares Regression --------------------------------------------------------------------------------------------
# Build the model on training set
pls.model <- train(
  sum_int~., data = data.train, method = "pls",
  scale = TRUE,
  trControl = trainControl("cv", number = 10),
  tuneLength = 10
)
## Print the best tuning parameter ncomp that
# minimize the cross-validation error, RMSE
summary(pls.model)

# Plot model RMSE vs different values of components
pc_perf<-data.frame(ncomp=pls.model$results$ncomp, rmse=pls.model$results$RMSE, rsquared=pls.model$results$Rsquared)
rmse.pls<-ggplot(pc_perf,aes(x = ncomp,y = rmse)) +
  geom_line()+
  # format
  scale_color_brewer(palette = "Dark2") +
  theme_bw() + 
  scale_x_continuous(n.breaks = 10)+
  xlab('Number of Compoments') +
  ylab('RMSE(cross-validation') +
  ggtitle("RMSE for each component")

rsquared.pls<-ggplot(pc_perf,aes(x = ncomp,y = rsquared)) +
  geom_line()+
  # format
  scale_color_brewer(palette = "Dark2") +
  theme_bw() + 
  scale_x_continuous(n.breaks = 10)+
  xlab('Number of Compoments') +
  ylab('Rsquared') +
  ggtitle("Rsquared for each component")

grid.arrange(rmse.pls,rsquared.pls,ncol=2)

# Compute predictions
pls.pred <- predict(pls.model,data.test)
# Model performance metrics
pls.mse<-sum((data.test$sum_int-pls.pred)^2)/length(data.test$sum_int)
pls.perf<-data.frame(
  MSE=pls.mse,
  Rsquare = caret::R2(pls.pred, data.test$sum_int)*100,
  RMSE = caret::RMSE(pls.pred, data.test$sum_int))

### Final metrics --------------------------------------------------------------------------------------------
#Create data Frame containing all the perfomance metrics
perfomance<-rbind(reg.perf,lasso.perf,rf.perf0,rf.perf1,bg.perf,pls.perf)
rownames(perfomance)<-c('ElasticNet','Lasso','RF0','RF1', 'GBM','PLS')
#Convert rownames to column
perfomance<-rownames_to_column(perfomance, "Methods")

png("perfomance.png")
p<-tableGrob(perfomance)
grid.arrange(p)
dev.off()

#Plot results
#MSE
total_mse<-perfomance %>% 
  # plot these data using columns
  ggplot(aes(x = forcats::fct_reorder(.f = Methods, 
                                      .x = MSE), 
             y = MSE,fill = MSE)) +
  geom_col() +
  # flip
  coord_flip() +
  # format
  scale_color_brewer(palette = "Dark2") +
  theme_bw() +
  theme(axis.title = element_text(),legend.position="none") + 
  xlab('Methods') +
  ylab('Mean Square Errror') +
  ggtitle("Mean Square Error")

#Rsquare
total_Rsquare<-perfomance %>% 
  # plot these data using columns
  ggplot(aes(x = forcats::fct_reorder(.f = Methods,.x = Rsquare), 
             y = Rsquare,fill = Rsquare)) +
  geom_col() +
  # flip
  coord_flip() +
  # format
  scale_color_brewer(palette = "Dark2") +
  theme_bw() +
  theme(axis.title = element_text(),legend.position = "none") + 
  xlab('Methods') +
  ylab('Rsquared (%)') +
  ggtitle("Rsquared")
grid.arrange(total_mse,total_Rsquare,ncol=2)

#Important Features 
grid.arrange(cor.imp,reg_coef,las_coef,rf_coef0,rf_coef1,boost_coef,nrow=2,ncol=3)
