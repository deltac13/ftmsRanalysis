#' Calculate DBE and DBE-O Values
#' 
#' Calculate double bond equivalent (DBE) and double bond equivalent minus Oxygen (DBE-O) values for peaks where empirical formula is available
#' 
#' @param ftmsObj an object of class 'peakData' or 'compoundData', typically a result of \code{\link{as.peakData}} or \code{\link{mapPeaksToCompounds}}.
#' @param valences a named list with the valence for each element.  Names must be any of 'C', 'H', 'N', 'O', 'S', 'P'. Values must be integers corresponding to the valence for each element.  Defaults to NULL, in which case the valences that result in the formula given in the details section are used.
#' 
#' @details 
#' \tabular{ll}{
#'  \tab If no valences are provided, DBE \eqn{= 1 + C - O - S - 0.5*(N + P + H)} \cr
#'  \tab If valences are provided DBE, \eqn{= 1 + \frac{\sum_{i}N_i(V_i-2)}{2}} where \eqn{N_i} and \eqn{V_i} are the number of atoms and corresponding valences.\cr
#'  \tab DBE-0 \eqn{= 1 + C - O - S - 0.5(N + P + H) - O}{= 1 + C - O - S - 0.5*(N + P + H) - O} \cr
#' }
#' 
#' @references Koch, B. P., & Dittmar, T. (2006). From mass to structure: an aromaticity index for high‐resolution mass data of natural organic matter. Rapid communications in mass spectrometry, 20(5), 926-932. 
#' @references Errata: Koch, B. P., & Dittmar, T. (2016). From mass to structure: an aromaticity index for high-resolution mass data of natural organic matter. Rapid communications in mass spectrometery, 30(1), 250. DOI: 10.1002/rcm.7433
#' 
#' @return an object of the same class as \code{ftmsObj} with a column in \code{e\_meta} giving DBE, DBE-O, and DBE_AI values
#'  
#' @author Lisa Bramer, Allison Thompson
#' 

calc_dbe <- function(ftmsObj, valences = NULL){
  
  # check that ftmsObj is of the correct class #
  if(!inherits(ftmsObj, "peakData") & !inherits(ftmsObj, "compoundData")) stop("ftmsObj must be an object of class 'peakData' or 'compoundData'")
  
  # get coefficients that will multiply each elemental count.  Each coefficient is equal to {valence}-2
  if(is.null(valences)){
    # coefficients that result in the equation given in @details
    coefs <- list('C' = 2, 'H' = -1, 'N' = 1, 'O' = 0, 'S' = 0, 'P' = 1)
  }
  else{
    cond1 <- inherits(valences, 'list')
    cond2 <- all(names(valences) %in% c('C', 'H', 'N', 'O', 'S', 'P'))
    if(!all(cond1, cond2)) stop("argument valences must be a named list of integers with names 'C', 'H', 'N', 'O', 'S', 'P' and values representing the valence for each element.")
    coefs <- lapply(c('C', 'H', 'N', 'O', 'S', 'P'), function(x) if(!is.null(valences[[x]])) valences[[x]]-2 else 2)
    names(coefs) <- c('C', 'H', 'N', 'O', 'S', 'P')
  }
  
  # pull e_meta out of ftmsObj #
  temp = ftmsObj$e_meta
  
  # get existing elemental counts
  C_counts = if(getCarbonColName(ftmsObj) %in% colnames(temp)) temp[,getCarbonColName(ftmsObj)] else 0
  H_counts = if(getHydrogenColName(ftmsObj) %in% colnames(temp)) temp[,getHydrogenColName(ftmsObj)] else 0
  N_counts = if(getNitrogenColName(ftmsObj) %in% colnames(temp)) temp[,getNitrogenColName(ftmsObj)] else 0
  O_counts = if(getOxygenColName(ftmsObj) %in% colnames(temp)) temp[,getOxygenColName(ftmsObj)] else 0
  S_counts = if(getSulfurColName(ftmsObj) %in% colnames(temp)) temp[,getSulfurColName(ftmsObj)] else 0
  P_counts = if(getPhosphorusColName(ftmsObj) %in% colnames(temp)) temp[,getPhosphorusColName(ftmsObj)] else 0
  
  temp$DBE = 1 + 0.5*(coefs[['C']]*C_counts + coefs[['H']]*H_counts + coefs[['N']]*N_counts + coefs[['O']]*O_counts + coefs[['S']]*S_counts + coefs[['P']]*P_counts)
  
  temp$DBE_O = 1 + 0.5*(2*C_counts - H_counts + N_counts + P_counts) - O_counts
  
  temp$DBE_AI = 1 + C_counts - O_counts - S_counts - 0.5*(N_counts + P_counts + H_counts)
  
  if(length(which(is.na(temp[,getMFColName(ftmsObj)]))) > 0){
    temp$DBE[which(is.na(temp[,getMFColName(ftmsObj)]))] = NA
    temp$DBE_O[which(is.na(temp[,getMFColName(ftmsObj)]))] = NA
    temp$DBE_AI[which(is.na(temp[,getMFColName(ftmsObj)]))] = NA
  }

  ftmsObj$e_meta = temp
  
  ftmsObj = setDBEColName(ftmsObj, "DBE")
  ftmsObj = setDBEoColName(ftmsObj, "DBE_O")
  ftmsObj = setDBEAIColName(ftmsObj, "DBE_AI")
  
  return(ftmsObj)
}