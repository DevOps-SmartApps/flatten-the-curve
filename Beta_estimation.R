rm(list=ls()) 
# Code to be embedded in the app

library(deSolve)
library(bbmle)

SIR.fit <- function(t, y, p) {
  with(as.list(c(y, p)), {
    dS <- -beta * S * I
    dI <-  beta * S * I - gamma * I - v * I
    dF <- v * I
    dC <- beta*S*I
    list(c(S = dS,I = dI, Fs = dF, C=dC))
  })
}

nLL = function(beta){
  parms <- c(beta = beta, gamma = 1/13, v = 0.00237)
  I0 <- 0.005
  S0 <- 1 - I0
  mintime <- 0
  maxtime <- 250
  out <- ode(y = c(S = S0, I = I0, FS = 0, C=0), times = seq(mintime, maxtime, 1), SIR.fit, parms)
  df <- data.frame(out)
 
  Model.pred=NULL
  # Extract the model predictions corresponding to the times
  # in the data
  for(i in seq(1,length(Idata$cumI))){
    ii = which(df$time==Idata$time[i])
    Model.pred[i] = df$cumI[ii]
  }
  # The negative LL. The RHS has dropped constants
  # that don't affect the location of the maximum
  res = sum((Model.pred - Idata$cumI)^2)
  return(res)
}

# Some data that was created to test the method:
Idata <- data.frame(time=c(1,5,10), cumI = c(.1,.12,.13))
# Find the MLE beta
fit = mle2(nLL, data = Idata, start=list(beta=.4))
beta.est=unname(coef(fit))
parms <- c(beta = beta.est, gamma = 1/13, v = 0.00237)
I0 <- 0.005
S0 <- 1 - I0
mintime <- 0
maxtime <- 250

out <- ode(y = c(S = S0, I = I0, FS = 0, C=0), times = seq(mintime, maxtime, 1), SIR.fit, parms)
df = data.frame(out)

par(mfrow = c(1,3))
plot(df$time, df$C, typ="l")
points(Idata$time, Idata$cumI)

# parameteric 95% CI
LowerCI = max(beta.est - 1.96*unname(stdEr(fit)),0)
UpperCI = beta.est + 1.96*unname(stdEr(fit))
# Lower 95% CI
parms <- c(beta = LowerCI, gamma = 1/13, v = 0.00237)
out.lower <- ode(y = c(S = S0, I = I0, FS = 0, C=0), times = seq(mintime, maxtime, 1), SIR.fit, parms)
df.lower = data.frame(out.lower)
lines(df.lower$time, df.lower$C, lty=2)

# Upper 95% CI
parms <- c(beta = UpperCI, gamma = 1/13, v = 0.00237)
out.upper <-out <- ode(y = c(S = S0, I = I0, FS = 0, C=0), times = seq(mintime, maxtime, 1), SIR.fit, parms)
df.upper = data.frame(out.upper)
lines(df.upper$time, df.upper$C, lty=2)

plot(df$time, df$I, typ="l")
lines(df.upper$time, df.upper$I, lty=2)
lines(df.lower$time, df.upper$I, lty=2)

# The last plot needs to be of
# time of the release of the last data vs.
# the new for this new data beta.est with 95% CIs 
