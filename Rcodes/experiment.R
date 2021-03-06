require("MASS")
require("cluster")
## Generate data in three slightly overlapping clusters.
## Each cluster is composed of N points generated by a normal distribution.
clusters.data <- function(n) {
    
    x1 <- rnorm(n);
    y1 <- rnorm(n);
    x2 <- -2 + rnorm(n);
    y2 <- -2 + rnorm(n);
    x3 <- 2 + rnorm(n);
    y3 <- 2 + rnorm(n);
    
    X <- c(x1,x2,x3)
    Y <- c(y1,y2,y3)

    data <- cbind(X,Y);
    return(data)

}

## Generate data in a straight line. This is used to test the hypothesis
## that diffusion distance doesn't work when the graph is a tree.

line.data <- function(n){
    
    X <- (1:n)/2
    Y <- seq(1,1,length=n)
    data <- cbind(X, Y)

    return(data)
}

spiral.data <- function(n){
    theta <- 2*pi*seq(0,4,length.out = n)
    radius <- seq(1,6,length.out = n)

    X <- radius * cos(theta)
    Y <- radius * sin(theta)

    data <- cbind(X,Y)

    return(data)
### plot(X, Y)
}

swiss.roll.data <- function(n){
    phi <- runif(n,5,13)
    Z <- runif(n,0,10)
    X <- phi*sin(phi)
    Y <- phi*cos(phi)

    data <- cbind(X,Y,Z)
    return(data)
}

clusters2.data <- function(n) {
    X1 <- rnorm(n);
    Y1 <- rnorm(n);
    X2 <- -4+rnorm(n);
    Y2 <- 4+rnorm(n);
    X3 <- 4+rnorm(n);
    Y3 <- 4+rnorm(n);

    X4 <- -4 + seq(0,by=0.2,length.out=41) + 0.1*rnorm(41)
    Y4 <- 4 + 0.1*rnorm(41)

    X5 <- -4 + seq(0,by=0.2,length.out = 21) + 0.1*rnorm(21)
    Y5 <- 4 - seq(0,by=0.2,length.out = 21) + 0.1*rnorm(21)

    
    X6 <- 4 - seq(0,by=0.2,length.out = 21) + 0.1*rnorm(21)
    Y6 <- 4 - seq(0,by=0.2,length.out = 21) + 0.1*rnorm(21)

    X <- c(X1,X2,X3,X4,X5,X6)
    Y <- c(Y1,Y2,Y3,Y4,Y5,Y6)
    data <- cbind(X,Y)
    return(data)
}

experiment1.diffusion <- function(data.type, n, t, k, epsilon, num.clust, sparsity, cutoff){

    if(data.type == "clusters") { data <- clusters.data(n) }
    else if(data.type == "spiral") { data <- spiral.data(n) }
    else if(data.type == "swiss") { data <- swiss.roll.data(n) }
    else { data <- line.data(n) }
    
    list.diffusion = diffusion.distance(data, t, k, epsilon, sparsity, cutoff)
    d.diffusion = list.diffusion$dist
    psi = list.diffusion$map
    tree.diffusion = hclust(as.dist(d.diffusion))
    cluster.diffusion = cutree(tree.diffusion, k = num.clust)
    data.table <- as.table(cbind(data, cluster.diffusion))
#    clusplot(data, cluster.diffusion, color = TRUE, shade = FALSE, labels = 0, lines = 0)
    plot(psi[,2], psi[,3], col = data.table[,4], xlab = "X", ylab = "Y")
    return(as.matrix(d.diffusion))
}

experiment1.resistance <- function(data.type, n, epsilon, num.clust, sparsity, cutoff){

    if(data.type == "clusters") { data <- clusters.data(n) }
    if(data.type == "spiral") { data <- spiral.data(n) }
    if(data.type == "line") { data <- line.data(n) }
    
    d.resistance = resistance.distance(data, epsilon, sparsity, cutoff)
    tree.resistance = hclust(as.dist(d.resistance))
    cluster.resistance = cutree(tree.resistance, k = num.clust)
    data.table <- as.table(cbind(data, cluster.resistance))
### clusplot(data, cluster.diffusion, color = TRUE, shade = FALSE, labels = 0, lines = 0)
    plot(data.table[,1], data.table[,2], col = data.table[,3], xlab = "X", ylab = "Y")
    return(as.matrix(d.resistance))
}

experiment.diffusion <- function(data, epsilon, t, numclust, k = 2, cmds = TRUE, outfile = NULL) {
    W <- gaussian.similarity(data, epsilon)
    diffusion.struct <- diffusion.distance(W, t)
    dist.diffusion <- diffusion.struct$dist
    map.diffusion <- diffusion.struct$map

    if(cmds == TRUE)
      loc <- cmdscale(dist.diffusion, k)
    else if(cmds == FALSE)
       loc <- map.diffusion[,2:(k+1)]

    tree.diffusion <- hclust(as.dist(dist.diffusion), method = "ward")
    cluster.diffusion <- cutree(tree.diffusion, numclust)
    if(!is.null(outfile))
      pdf(outfile, width = 6, useDingbats = FALSE)
    plot(loc, col = cluster.diffusion, xlab = "X", ylab = "Y", asp = 1)
    if(!is.null(outfile))
      dev.off()
}

experiment.ect <- function(data, epsilon, numclust, k = 2, cmds = TRUE, outfile = NULL) {
    W <- gaussian.similarity(data, epsilon)
    ect.struct <- expected.commute.time(W)
    dist.ect <- ect.struct$dist
    map.ect <- ect.struct$map

    if(cmds == TRUE)
      loc <- cmdscale(dist.ect, k)
    else if(cmds == FALSE)
       loc <- map.ect[,2:(k+1)]

    tree.ect <- hclust(as.dist(dist.ect), method = "ward")
    cluster.ect <- cutree(tree.ect, numclust)
    if(!is.null(outfile))
      pdf(outfile, width = 6, useDingbats = FALSE)
    plot(loc, col = cluster.ect, xlab = "X", ylab = "Y", asp = 1)
    if(!is.null(outfile))
      dev.off()
}

twostep.experiment <- function(n, epsilon, t = 5, k = 2, cmds = TRUE, outpdf = NULL){
    data <- line.data(n)
    W <- gaussian.similarity(data, epsilon)
    P <- transition.matrix(W)
    dist.diffusion <- diffusion.distance(P, t)

    cv <- 0.1*data[,1]

    if(!is.null(outpdf)){
        pdf("twostep_data.pdf", width = 6, useDingbats = FALSE, asp = 1) 
        plot(data, col = cv)
        dev.off()
    }

    if(cmds == TRUE)
      loc  <- cmdscale(dist.diffusion, k)
    else if(cmds == FALSE)
       loc <- diffusion.map(P,t,k=2)
    
    if(!is.null(outpdf))
      pdf("twosteps_diffusion.pdf", width = 6, useDingbats = FALSE)
    plot(loc, col = cv, xlab = "X", ylab = "Y", asp = 1)
    if(!is.null(outpdf))
      dev.off()
    return(cbind(data,loc))
}

twostep.ect.experiment <- function(n, epsilon, k = 2, cmds = TRUE, outpdf = NULL){
    data <- line.data(n)
    W <- gaussian.similarity(data, epsilon)
    P <- transition.matrix(W)
    dist.ect <- ect(P)

    cv <- 0.1*data[,1]

    if(!is.null(outpdf)){
        pdf("twostep_data.pdf", width = 6, useDingbats = FALSE, asp = 1) 
        plot(data, col = cv)
        dev.off()
    }

    if(cmds == TRUE)
      loc <- cmdscale(dist.ect, k)
    else if(cmds == FALSE)
      loc <- ect.map(P,k=2)
    
    if(!is.null(outpdf))
      pdf("twosteps_ect.pdf", width = 6, useDingbats = FALSE)
    plot(loc, col = cv, xlab = "X", ylab = "Y", asp = 1)
    if(!is.null(outpdf))
      dev.off()
    
    return(cbind(data,loc))
}
    
