#' EcolUtils: Utilities for community ecology analysis.
#'
#' The package \pkg{EcolUtils} provides tools for community ecology analysis not present in up-to-date available packages. Designed with molecular 16S-derived data in mind.
#'
#'@details The package \pkg{EcolUtils} depends on \pkg{vegan} which can be installed from CRAN.
#' 
#' To see the preferable citation of the package, type \code{citation("EcolUtils")}.
#'@docType package
#'@name EcolUtils
#'@author Guillem Salazar <guillems@@ethz.ch>

NULL


#' Rarefaction of a community matrix with permutations
#'
#' This function generates one randomly rarefied community data frame through \code{n} repeated independent rarefactions.
#' @param x Community data, a matrix-like object.
#' @param sample Subsample size (\code{min(rowSums(x))} as default)
#' @param n Number of independent rarefactions.
#' @param round.out logical; should output be rounded.
#' @details
#' Function \code{rrarefy.perm} generates one randomly rarefied community data frame by computing \code{n} rarefied communities with \code{rrarefy} in \pkg{vegan} and computing the mean.
#' The average value for each cell may (or may not) be rounded by using \code{round.out} parameter.
#' @keywords EcolUtils
#' @return Rarefied community.
#' @export
#' @author Guillem Salazar <guillems@@ethz.ch>
#' @examples
#' library(vegan)
#' data(varespec)
#' rrarefy.perm(varespec*100)

rrarefy.perm<-function(x,sample=min(rowSums(x)),n=100,round.out=T){
  require(vegan)
  y<-rrarefy(x,sample)
  for (i in 2:n){
    cat("Permutation ",i," out of ",n,"\n")
    y<-y+rrarefy(x,sample)	
  }
  if (round.out==T) y<-round(y/n)
  if (round.out==F) y<-y/n
  y}
  
#' Pairwise comparisons for Permutational Multivariate Analysis of Variance Using Distance Matrices
#'
#' Pairwise comparisons for all pairs of levels of a factor by using for Permutational MANOVA.
#' @param dist.mat Dissimilarity object
#' @param Factor Factor whose levels are to be compared.
#' @param nper Number of permutations.
#' @param corr.method P-value's correction method (from \code{p.adjust}).
#' @details Basically the \code{adonis.pair} function applies the \code{adonis} function from \pkg{vegan} to all pairs of levels of a factor. P-values are then corrected with \code{p.adjust}.
#' @keywords EcolUtils
#' @return Data frame with the R2, p-values and corrected p-values for each pairwise combination.
#' @export
#' @author Guillem Salazar <guillems@@ethz.ch>
#' @examples
#' library(vegan)
#' data(dune)
#' data(dune.env)
#' adonis.pair(vegdist(dune),dune.env$Management)

adonis.pair<-function(dist.mat,Factor,nper=1000,corr.method="fdr"){
  require(vegan)
  as.factor(Factor)
  comb.fact<-combn(levels(Factor),2)
  pv<-NULL
  R2<-NULL
  SS<-NULL
  MeanSqs<-NULL
  F.Model<-NULL
  for (i in 1:dim(comb.fact)[2]){
    model.temp<-adonis(as.dist(as.matrix(dist.mat)[Factor==comb.fact[1,i] | Factor==comb.fact[2,i],Factor==comb.fact[1,i] | Factor==comb.fact[2,i]])~Factor[Factor==comb.fact[1,i] | Factor==comb.fact[2,i]],permutations=nper)
    pv<-c(pv,model.temp$aov.tab[[6]][1])
    R2<-c(R2,model.temp$aov.tab$R2[1])
    SS<-c(SS,model.temp$aov.tab[[2]][1])
    MeanSqs<-c(MeanSqs,model.temp$aov.tab[[3]][1])
    F.Model<-c(F.Model,model.temp$aov.tab[[4]][1])
    }
  pv.corr<-p.adjust(pv,method=corr.method)
  data.frame(combination=paste(comb.fact[1,],comb.fact[2,],sep=" <-> "),SumsOfSqs=SS,MeanSqs=MeanSqs,F.Model=F.Model,R2=R2,P.value=pv,P.value.corrected=pv.corr)}

#' Specialist/Generalist classification of OTUs based on niche width and permutation algorithms
#'
#' Classification of OTUs in generalists / specialists / non-significant based on the deviation of niche width indexes (\code{shanon}, \code{levins} or \code{occurrence}) from null values computed with permutation algorithms for community matrices.
#' @param comm.tab Community data, a matrix-like object (samples as rows; OTUs as columns).
#' @param niche.width.method Niche width index (from \code{niche.width} in \pkg{spaa}): \code{levins} (default) or \code{shannon}. Or simply the \code{occurrence}: the number of samples where an OTU occurs.
#' @param n Number of permutations.
#' @param  perm.method Method for null model construction (from \code{permatswap} in \pkg{vegan}). Currently, only \code{quasiswap} (default) has been thoroughly tested.
#' @param  probs Probabilities for confidence interval calculations.
#' @details Basically the \code{spec.gen} function computes a niche width index for each OTU in the \code{comm.tab}. The mean index value and CI for each OTU is computed for \code{n} null matrices created through permutation algorithms. Each OTU is classified as specialist / generalist / non significant if the real value is lower / higher / within the CI.
#' @keywords EcolUtils
#' @return Data frame with the observed niche width value, the mean and CI null values and the classification of each OTU.
#' @export
#' @author Guillem Salazar <guillems@@ethz.ch>
#' @examples
#' library(RCurl)
#' x<-getURL("https://raw.githubusercontent.com/GuillemSalazar/MolEcol_2015/master/OTUtable_Salazar_etal_2015_Molecol.txt")
#' comm.tab<-read.table(text=x,sep="\t",row.names=1,header=TRUE,comment.char="@@")
#' comm.tab<-t(comm.tab[,1:60])
#' comm.tab<-comm.tab[,which(colSums(comm.tab)>0)]
#' res<-spec.gen(comm.tab,n=100)
#' 
#' comm.tab.bin<-ceiling(comm.tab/max(comm.tab))
#' plot(colSums(comm.tab),colSums(comm.tab.bin)/dim(comm.tab.bin)[1],col=res$sign,pch=19,log="x",xlab="Abundance",ylab="Occurrence")
#' legend("bottomright",levels(res$sign),col=1:3,pch=19,inset=0.01,cex=0.7)

spec.gen<-function(comm.tab,niche.width.method="levins",perm.method="quasiswap",n=1000,probs=c(0.025,0.975)){
  require(spaa)
  require(vegan)
  occurrence<-function(x){apply(ceiling(x/max(x)),2,sum)}
  n<-n
  if (niche.width.method=="occurrence") levin.index.real<-occurrence(comm.tab) else levin.index.real<-as.numeric(niche.width(comm.tab,method=niche.width.method))
  names(levin.index.real)<-colnames(comm.tab)
  
  levin.index.simul<-matrix(NA,ncol=dim(comm.tab)[2],nrow=n)
  for (i in 1:n){
    if (niche.width.method=="occurrence") levin.index.simul[i,]<-occurrence(permatswap(comm.tab,perm.method,times=1)$perm[[1]]) else levin.index.simul[i,]<-as.numeric(niche.width(permatswap(comm.tab,perm.method,times=1)$perm,method=niche.width.method))
  }
  colnames(levin.index.simul)<-colnames(comm.tab)
  levin.index.simul<-as.data.frame(levin.index.simul)
  media<-apply(levin.index.simul,2,mean)
  ci<-apply(levin.index.simul,2,quantile,probs=probs)
  resultats<-data.frame(observed=levin.index.real,mean.simulated=media,lowCI=ci[1,],uppCI=ci[2,],sign=NA)
  for (j in 1:dim(resultats)[1]){
    if (resultats$observed[j]>resultats$uppCI[j]) resultats$sign[j]<-"GENERALIST"
    if (resultats$observed[j]<resultats$lowCI[j]) resultats$sign[j]<-"SPECIALIST"
    if (resultats$observed[j]>=resultats$lowCI[j] & resultats$observed[j]<=resultats$uppCI[j]) resultats$sign[j]<-"NON SIGNIFICANT"
  }
  resultats$sign<-as.factor(resultats$sign)
  resultats}

#' Optimized Specialist/Generalist Classification of OTUs
#'
#' Efficiently classifies OTUs as generalists, specialists, or non-significant based on the deviation of niche width indices (\code{shannon}, \code{levins}, or \code{occurrence}) from null values. These null values are generated through permutation algorithms applied to community matrices. This optimized version leverages parallel processing to significantly improve performance on large datasets.
#'
#' @param comm.tab Community data, a matrix-like object with samples as rows and OTUs as columns.
#' @param niche.width.method Specifies the niche width index to use: \code{levins} (default), \code{shannon}, or \code{occurrence} (the number of samples where an OTU occurs).
#' @param n The number of permutations to perform, impacting the robustness and computation time.
#' @param perm.method Method for null model construction, with \code{quasiswap} (default) from \pkg{vegan} being thoroughly tested.
#' @param probs Probabilities for confidence interval calculations, allowing for customizable significance levels.
#' @details The function computes a niche width index for each OTU using either the specified method or the occurrence across the community matrix. For each OTU, the mean index value and confidence intervals are determined from \code{n} permuted matrices. OTUs are then classified based on whether their real niche width falls below, within, or above these confidence intervals. This approach enables a nuanced understanding of OTU niche specialization within ecological communities.
#' @keywords EcolUtils
#' @return A dataframe containing the observed niche width value, the mean and confidence intervals of simulated values, and the classification of each OTU as either a specialist, generalist, or non-significant.
#' @export
#' @author Optimized by Chris Keneally <christopher.keneally@@adelaide.edu.au>, Original by Guillem Salazar <guillems@@ethz.ch>
#' @examples
#' library(RCurl)
#' x <- getURL("https://raw.githubusercontent.com/GuillemSalazar/MolEcol_2015/master/OTUtable_Salazar_etal_2015_Molecol.txt")
#' comm.tab <- read.table(text=x, sep="\t", row.names=1, header=TRUE, comment.char="@")
#' comm.tab <- t(comm.tab[,1:60])
#' comm.tab <- comm.tab[,which(colSums(comm.tab) > 0)]
#' res <- spec.gen.optimized(comm.tab, n=100)
#'
#' comm.tab.bin <- ceiling(comm.tab / max(comm.tab))
#' plot(colSums(comm.tab), colSums(comm.tab.bin) / dim(comm.tab.bin)[1], col=res$sign, pch=19, log="x", xlab="Abundance", ylab="Occurrence")
#' legend("bottomright", levels(res$sign), col=1:3, pch=19, inset=0.01, cex=0.7)

spec.gen.optimized <- function(comm.tab, niche.width.method = "levins", perm.method = "quasiswap", n = 1000, probs = c(0.025, 0.975)) {
  # Calculate real niche width or occurrence
  if (niche.width.method == "occurrence") {
    levin.index.real <- colSums(ceiling(comm.tab / max(comm.tab)))
  } else {
    levin.index.real <- as.numeric(niche.width(comm.tab, method = niche.width.method))
  }
  names(levin.index.real) <- colnames(comm.tab)
  
  # Setup for parallel computation
  cl <- makeCluster(detectCores() - 1) # Leave one core free for system processes
  clusterExport(cl, varlist = c("comm.tab", "niche.width.method", "perm.method", "n", "probs"))
  clusterEvalQ(cl, library(spaa))
  clusterEvalQ(cl, library(vegan))
  
  # Parallel computation of simulated indices
  levin.index.simul <- parLapply(cl, 1:n, function(i) {
    if (niche.width.method == "occurrence") {
      return(colSums(ceiling(permatswap(comm.tab, perm.method, times = 1)$perm[[1]] / max(comm.tab))))
    } else {
      return(as.numeric(niche.width(permatswap(comm.tab, perm.method, times = 1)$perm, method = niche.width.method)))
    }
  })
  
  stopCluster(cl)
  
  levin.index.simul <- do.call(rbind, levin.index.simul)
  colnames(levin.index.simul) <- colnames(comm.tab)
  
  # Compute mean and confidence intervals
  media <- colMeans(levin.index.simul)
  ci <- t(apply(levin.index.simul, 2, quantile, probs = probs))
  
  # Classify OTUs based on real index vs. CI
  resultats <- data.frame(observed = levin.index.real, mean.simulated = media, lowCI = ci[, 1], uppCI = ci[, 2], sign = NA)
  
  resultats$sign <- ifelse(resultats$observed > resultats$uppCI, "GENERALIST",
                           ifelse(resultats$observed < resultats$lowCI, "SPECIALIST", "NON SIGNIFICANT"))
  
  resultats$sign <- factor(resultats$sign)
  
  return(resultats)
}

#' Seasonality test based on autocorrelation and null communities
#'
#' Classification of OTU's seasonality based on the sum of their auto-correaltion function and on null community matrices.
#' @param comm.tab Community data, a matrix-like object (samples as rows; OTUs as columns). Samples should be ordered and representing a time series.
#' @param n Number of permutations.
#' @param  probs Probabilities for confidence interval calculations.
#' @param lag.max Maximum lag at which to calculate the acf. See the \code{acf} function.
#' @details Basically the \code{seasonality.test} function computes the auto-correlation function (acf) for each OTU in the \code{comm.tab} through the \code{acf} function in the \pkg{stats} package. The sum of the absolute values of the acf is computed as the seasonality index for each OTU.
#' This seasonality index and CI for each OTU is also computed for \code{n} null community matrices. The null matrices are created by randomly shuffling the rows in \code{comm.tab}.  Each OTU is classified depending whether the real seasonality index is lower / higher / within the CI.
#' @keywords EcolUtils
#' @return Data frame with the observed seasonality index, the mean and CI null values and the classification of each OTU.
#' @export
#' @author Guillem Salazar <guillems@@ethz.ch>
#' @examples
#' library(RCurl)
#' # It runs but makes no ecological sense as data does not represent a time-series
#' x<-getURL("https://raw.githubusercontent.com/GuillemSalazar/MolEcol_2015/master/OTUtable_Salazar_etal_2015_Molecol.txt")
#' comm.tab<-read.table(text=x,sep="\t",row.names=1,header=TRUE,comment.char="@@")
#' comm.tab<-t(comm.tab[,1:60])
#' comm.tab<-comm.tab[,which(colSums(comm.tab)>0)]
#' res<-seasonality.test(comm.tab,n=10)

seasonality.test<-function(comm.tab,n=1000,probs=c(0.025, 0.975),lag.max=120,na.action=na.pass) 
{
  require(vegan)
  
  season.index<-function(x){
    acf.all<-apply(as.matrix(x),2,acf,plot=F,lag.max=lag.max,na.action=na.pass)
    acf.all<-sapply(acf.all,"[[",1)
    apply(acf.all,2,function(x) sum(abs(x)))
  }
  
  n<-n
  season.index.real<-season.index(comm.tab)
  
  names(season.index.real) <- colnames(comm.tab)
  season.index.simul<-matrix(NA, ncol = dim(comm.tab)[2],nrow = n)
  for (i in 1:n) {
    season.index.simul[i, ]<-season.index(comm.tab[sample(1:nrow(comm.tab)),])
  }
  colnames(season.index.simul) <- colnames(comm.tab)
  season.index.simul <- as.data.frame(season.index.simul)
  media <- apply(season.index.simul, 2, mean)
  ci <- apply(season.index.simul, 2, quantile, probs = probs)
  resultats <- data.frame(observed = season.index.real, mean.simulated = media,lowCI = ci[1, ], uppCI = ci[2, ], sign = NA)
  for (j in 1:dim(resultats)[1]) {
    if (resultats$observed[j] > resultats$uppCI[j]) 
      resultats$sign[j] <- "SIGNIFICANTLY HIGHER"
    if (resultats$observed[j] < resultats$lowCI[j]) 
      resultats$sign[j] <- "SIGNIFICANTLY LOWER"
    if (resultats$observed[j] >= resultats$lowCI[j] & resultats$observed[j] <= 
        resultats$uppCI[j]) 
      resultats$sign[j] <- "NON SIGNIFICANT"
  }
  resultats$sign <- as.factor(resultats$sign)
  resultats
}

#' Niche value computation for OTUs in a community through abundance-weighted mean and matrix randomization.
#'
#' Computation of the abundance-weighted mean of an environmental variable for all OTUs in a community and statistical comparison to randomized communities.
#' @param comm.tab Community data, a matrix-like object (samples as rows; OTUs as columns).
#' @param env.var Environmental variable as a numeric vector.
#' @param n Number of permutations.
#' @param  probs Probabilities for confidence interval calculations.
#' @details The \code{niche.val} function computes the abundance-weighted mean of an environmental variable for each OTU in the \code{comm.tab}. The mean value and CI for each OTU is computed for \code{n} null matrices. The null matrices are created by randomly shuffling the rows in \code{comm.tab}.  Each OTU is classified depending whether the real niche value is lower / higher / within the CI.
#' @keywords EcolUtils
#' @return Data frame with the observed niche value, the mean and CI null values and the classification of each OTU based on randomizations.
#' @export
#' @author Guillem Salazar <guillems@@ethz.ch>

niche.val<-function(comm.tab,env.var,n=1000,probs=c(0.025,0.975)){
  require(vegan)
  stat.real<-apply(comm.tab,2,function (x) {weighted.mean(env.var,x,na.rm=T)})
  stat.simul<-matrix(NA,ncol=dim(comm.tab)[2],nrow=n)
  for (i in 1:n){
    print(paste("Rarefaction",i))
    stat.simul[i,]<-apply(comm.tab[sample(1:nrow(comm.tab)),],2,function (x) {weighted.mean(env.var,x,na.rm=T)})
  }
  colnames(stat.simul)<-colnames(comm.tab)
  simul<-as.data.frame(stat.simul)
  media<-apply(stat.simul,2,mean,na.rm=T)
  ci<-apply(stat.simul,2,quantile,probs=c(0.025,0.975),na.rm=T)
  resultats<-data.frame(observed=stat.real,mean.simulated=media,lowCI=ci[1,],uppCI=ci[2,],sign=NA)
  
  classify.sign<-function (x){
    if (is.na(x[1])) NA
    else if (x[1]>x[4]) "HIGHER"
    else if (x[1]<x[3]) "LOWER"
    else if (x[1]>=x[3] & x[1]<=x[4]) "NON SIGNIFICANT"}
  
  resultats$sign<-as.factor(apply(resultats,1,classify.sign))
  resultats
}

#' Niche range computation for OTUs in a community through matrix randomization.
#'
#' Computation of the range of an environmental variable for all OTUs in a community and statistical comparison to randomized communities.
#' @param comm.tab Community data, a matrix-like object (samples as rows; OTUs as columns).
#' @param env.var Environmental variable as a numeric vector.
#' @param n Number of permutations.
#' @param  probs Probabilities for confidence interval calculations.
#' @details The \code{niche.val} function computes the range of values of an environmental variable where each OTU is present. The mean value and CI for each OTU is computed for \code{n} null matrices. The null matrices are created by randomly shuffling the rows in \code{comm.tab}.  Each OTU is classified depending whether the real niche range is lower / higher / within the CI.
#' @keywords EcolUtils
#' @return Data frame with the observed niche range value, the mean and CI null values and the classification of each OTU based on randomizations.
#' @export
#' @author Guillem Salazar <guillems@@ethz.ch>

niche.range<-function (comm.tab, env.var, n = 1000, probs = c(0.025, 0.975)) 
{
  require(vegan)
  stat.real <- apply(comm.tab, 2, function(x) {
    abs(range(env.var[which(x>0)],na.rm=T)[1]-range(env.var[which(x>0)],na.rm=T)[2])
  })
  stat.simul <- matrix(NA, ncol = dim(comm.tab)[2], nrow = n)
  for (i in 1:n) {
    print(paste("Rarefaction", i))
    stat.simul[i, ] <- apply(comm.tab[sample(1:nrow(comm.tab)), 
                                      ], 2, function(x) {
                                        abs(range(env.var[which(x>0)],na.rm=T)[1]-range(env.var[which(x>0)],na.rm=T)[2])
                                      })
  }
  colnames(stat.simul) <- colnames(comm.tab)
  simul <- as.data.frame(stat.simul)
  media <- apply(stat.simul, 2, mean, na.rm = T)
  ci <- apply(stat.simul, 2, quantile, probs = c(0.025, 0.975), 
              na.rm = T)
  resultats <- data.frame(observed = stat.real, mean.simulated = media, 
                          lowCI = ci[1, ], uppCI = ci[2, ], sign = NA)
  classify.sign <- function(x) {
    if (is.na(x[1])) 
      NA
    else if (x[1] > x[4]) 
      "HIGHER"
    else if (x[1] < x[3]) 
      "LOWER"
    else if (x[1] >= x[3] & x[1] <= x[4]) 
      "NON SIGNIFICANT"
  }
  resultats$sign <- as.factor(apply(resultats, 1, classify.sign))
  resultats
}

#' Split moving-window distance analysis
#'
#' Split moving-window analysis based on multivariate community data and permutations.
#' @param comm.dist.mat Dissimilarity matrix.
#' @param env.var Vector representing a continuous environmental variable.
#' @param w.size Windows size (has to be even).
#' @param  probs Probabilities for confidence interval calculations.
#' @param nrep Number of randomizations for significance computation.
#' @details For each window the data is divided in two halves and the mean distance between samples belonging to a different half is divided by the mean distance between samples belonging to the same half. This is used as an statistic for which \code{nrep} null statistics are computed by resampling the order of the distance matrix and significance is computed. A z-score of the statistic is also provided.
#' @keywords EcolUtils
#' @return List containing: 1) data frame with the mean \code{env.var} value of the two central samples of the window, the min and max \code{env.var} values of the window, the statistic, its z-score and significance. 2) The mean and two quantiles of the null statistic based on the \code{probs}, all the null values and a window-to-sample map.
#' @export
#' @author Guillem Salazar <guillems@@ethz.ch>
#' @examples
#' library(vegan)
#' data("varespec")
#' data("varechem")
#' tmp<-smwda(vegdist(varespec),varechem$N)
#' plot(tmp$windows$env.var.mean,tmp$windows$stat.real.zscore,col=tmp$windows$sign,type="b",pch=19)

smwda<-function(comm.dist.mat,env.var,w.size=10,nrep=1000,probs=c(0.025,0.975)){
  comm.dist.mat<-as.matrix(comm.dist.mat)
  starting.points<-1:(nrow(comm.dist.mat)-w.size)
  if (w.size %% 2!=0) stop("Table needs to have an even number of samples (rows)")
  if (nrow(comm.dist.mat)!=ncol(comm.dist.mat)) stop("comm.dist.mat needs to be a square matrix representing dissimilarity values between samples")
  ordre<-order(env.var)
  env.var<-env.var[ordre]
  
  comm.dist.mat<-as.matrix(comm.dist.mat[ordre,ordre])
  
  fun<-function(start,comm.dist.mat,w.size){
    tmp<-comm.dist.mat[start:(start+w.size-1),start:(start+w.size-1)]
    diag(tmp)<-NA
    tmp[upper.tri(tmp)]<-NA
    mean(tmp[(1+w.size/2):w.size,1:(w.size/2)])/mean(c(tmp[1:(w.size/2),1:(w.size/2)],tmp[(1+w.size/2):w.size,(1+w.size/2):w.size]),na.rm = T)
  }
  
  rnd.fun<-function(comm.dist.mat,w.size){
    rnd.pos<-sample(1:nrow(comm.dist.mat),nrow(comm.dist.mat),replace=F)
    fun(1,comm.dist.mat=comm.dist.mat[rnd.pos,rnd.pos],w.size=w.size)
  }
  
  stat.real<-sapply(starting.points,function(x){fun(x,comm.dist.mat=comm.dist.mat,w.size=w.size)})
  stat.real.zscore<-scale(stat.real,center = T,scale = T)
  stat.random<-replicate(nrep,rnd.fun(comm.dist.mat,w.size))
  env.var.mean<-sapply(starting.points,function(x){mean(env.var[c(x+w.size/2-1,x+w.size/2)])})
  env.var.min<-sapply(starting.points,function(x){min(env.var[x:(x+w.size-1)])})
  env.var.max<-sapply(starting.points,function(x){max(env.var[x:(x+w.size-1)])})
  sign<-sapply(stat.real,function(x){if (x>quantile(stat.random,probs=probs[2]) | x<quantile(stat.random,probs=probs[1])) "sign" else "N.S"})
  
  window.sample.map<-sapply(starting.points,function(x){tmp<-rep(0,nrow(comm.dist.mat));tmp[x:(x+w.size-1)]<-1;t(tmp)})
  rownames(window.sample.map)<-rownames(comm.dist.mat)
  colnames(window.sample.map)<-paste("window",starting.points,sep="")
  
  list(windows=data.frame(env.var.mean,env.var.min,env.var.max,stat.real,stat.real.zscore,sign,row.names = paste("window",starting.points,sep="")),random.quantiles=quantile(stat.random,probs=probs),random.mean=mean(stat.random),random.values=stat.random,window.sample.map=t(window.sample.map))
  
}
