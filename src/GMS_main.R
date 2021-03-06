GMS_main <- function(ini_snps_bk, init_selsnp, j, mm, cv_samples, geno2, phenotype1, preset_fname, ix, breakx){
  library(caret)
  library(rrBLUP)
  sink(file = paste0("CV-", j, "_", mm, ".log"))
  ini_snps = ini_snps_bk
  o_delta <- 1
  sel_snps <- init_selsnp
  cat(paste0("CV Number ", j, ": Start","\n"), sep="")
  f_time <- Sys.time()
  #(8-1)Cheking prediction (correlation) rate for all markers

  cat(paste0("CV Number ", j, ": Check prediction (correlation) rate for all markers using ", mm, " model.","\n"), sep="")
  train_samples = which(cv_samples != j)
  train_geno = geno2[train_samples,]
  val_geno = geno2[-train_samples,]
  train_pheno = phenotype1[train_samples]
  val_pheno = phenotype1[-train_samples]

  nTrainSam = length(train_samples)
  nValSam = length(val_pheno)
  nGeno = dim(train_geno)[2]
  nSamGen = c(nTrainSam, nValSam, nGeno)

  all_train_acc = NULL
  all_val_acc = NULL
  selected_train_acc = NULL
  selected_val_acc = NULL
  
  if (allm == TRUE){
    if (mm == "RRB"){
      fit = RRb_func(train_pheno, train_geno, val_geno)
      val_pred = fit$val_predicted
      train_pred = fit$train_predicted
      fit_model = fit$model
    }
    if (mm == "BTS"){
      fit = RF_func(train_pheno, train_geno, val_geno, "MS")
      val_pred = fit$val_predicted
      train_pred = fit$train_predicted
      fit_model = fit$model
    }
    train_acc = cor(train_pred, train_pheno, use = "complete")
    val_acc = cor(val_pred, val_pheno, use = "complete")
    all_train_acc = c(all_train_acc, as.vector(train_acc))
    all_val_acc = c(all_val_acc, as.vector(val_acc))
  } else {
    train_acc = "-"
    val_acc = "-"
    all_train_acc = c(all_train_acc, as.vector(train_acc))
    all_val_acc = c(all_val_acc, as.vector(val_acc))
  }

  cat(paste0("CV Number ", j, ": Prediction (correlation) rate for all markers using ", mm, " is ", train_acc, " train acc ", val_acc, " val acc ", "\n"), sep="")
  cat(paste0("CV Number ", j, ": Prediction running time for all markers is ", format(difftime(Sys.time(), f_time), usetz = TRUE), "\n"), sep="")

  #inisum[[paste0("CV-", j, "_", mm)]] <- format(difftime(Sys.time(), f_time), usetz = TRUE)
  inisum1 <- format(difftime(Sys.time(), f_time), usetz = TRUE)

  #(8-2)Selecting initial markers
  ix1 <- ix
  if(length(preset_fname) != 0){
    preset_idx = match(preset_fname, ix1)
    ix1 <- ix1[-preset_idx]
    pp_ix = preset_fname
    ini_snps = 0
    train_ix = pp_ix
    rm(pp_ix)
  } else {
      init_set <- ix1[1:ini_snps]
      train_ix = init_set
  }

  r=0
  except_ix <- NULL
  except_tix <- NULL
  except_ixc <- 0
  add_ix <- train_ix
  result_train_acc = 0
  result_val_acc = 0
  ms_out <- list()
  t_add <- train_ix
  train_itr_geno <- train_geno[,train_ix]
  val_itr_geno <- val_geno[,train_ix]
  invisible(gc(verbose=FALSE, reset=TRUE, full=TRUE))

  #(8-3)Cheking prediction (correlation) rate for initial markers
  if (mm == "RRB"){
    fit_itr = RRb_func(train_pheno, train_itr_geno, val_itr_geno)
    val_pred_itr_pheno = fit_itr$val_predicted
    train_pred_itr_pheno = fit_itr$train_predicted
    fit_itr_model = fit_itr$model
  }
  if (mm == "BTS"){
    train_itr_geno = data.frame(train_itr_geno)
    colnames(train_itr_geno) = train_ix
    val_itr_geno = data.frame(val_itr_geno)
    colnames(val_itr_geno) = train_ix
    fit_itr = RF_func(train_pheno, train_itr_geno, val_itr_geno, "MS")
    val_pred_itr_pheno = fit_itr$val_predicted
    train_pred_itr_pheno = fit_itr$train_predicted
    fit_itr_model = fit_itr$model
  }

  train_itr_acc = cor(train_pred_itr_pheno, train_pheno, use = "complete")
  val_itr_acc = cor(val_pred_itr_pheno, val_pheno, use = "complete")

  #(8-4)Checking initial result
  ms_out[[1]] <- c(train_itr_acc, train_ix)
  k=2
  cat(paste0("CV Number ", j, ": Initial marker set's correlation rate is ", round(train_itr_acc,6), " in train, ", round(val_itr_acc,6), " in validation ", "\n"), sep="")
  result_train_acc = c(result_train_acc, train_itr_acc)
  result_val_acc = c(result_val_acc, val_itr_acc)

  #(8-5)Starting marker selection
  i=1
  max_noid <- 0
  max_noid2 <- 0
  s_time <- Sys.time()
  cat(paste0("CV Number ", j, ": Start marker selection at ", format(s_time, usetz = T), "\n"), sep="")
  readc = length(train_ix)
  readcc = length(train_ix)
  break_n = round(length(ix1) * breakx)
  bbx = round(breakx * 100,2)
  cat(paste0(" -- Stop condition: if the correlation rate does not increase ", break_n, " times consecutively (", bbx, "% of the total number of markers), the selection process is stopped.", "\n"), sep="")
  while (val_itr_acc < acc1){
    readcc = readcc + 1
    if (max_noid > 0 & max_noid == break_n){
      cat(paste0("STOP condition1: correlation rate did not increase ", break_n, " times in succession, so stop marker selection", "\n\n"), sep="")
      break
    }
    c5 = i %% 500
    if (c5 == c(0)){
      cat(paste0(i, " markers were read...", "\n"), sep="")
    }
    #(8-6) Selecting SNPs
    if (mm == "BTS"){
      add_snps = ix1[(ini_snps + (sel_snps*(i-1)+1)):(ini_snps + (sel_snps*(i)))]
      new_train_ix <- c(train_ix, add_snps)
      if (sum(is.na(new_train_ix)) >= 1){
        cat("STOP condition2: All markeres were read, so stop this CV", '\n\n')
        break
      }
    } else {
      add_snps = ix1[(ini_snps + (sel_snps*(i-1) +1)):(ini_snps + (sel_snps*(i)))]
      new_train_ix <- c(train_ix, add_snps)
      if (sum(is.na(init_set)) >= 1){
        cat("STOP condition2: All markeres were read, so stop this CV", '\n\n')
        break
      }
    }

    #(8-7) Cheking prediction (correlation) rate for selected markers
    train_itr_geno <- train_geno[,new_train_ix]
    val_itr_geno <- val_geno[,new_train_ix]
    if (mm == "RRB"){
      fit_itr = RRb_func(train_pheno, train_itr_geno, val_itr_geno)
      train_pred_itr_pheno = fit_itr$train_predicted
      val_pred_itr_pheno = fit_itr$val_predicted
      fit_itr_model = fit_itr$model
    }
    if (mm == "BTS"){
      fit_itr = RF_func(train_pheno, train_itr_geno, val_itr_geno, "MS")
      train_pred_itr_pheno = fit_itr$train_predicted
      val_pred_itr_pheno = fit_itr$val_predicted
      fit_itr_model = fit_itr$model
    }

    acc_train = cor(train_pred_itr_pheno, train_pheno, use = "complete")
    acc_val = cor(val_pred_itr_pheno, val_pheno, use = "complete")

    check = (acc_val - val_itr_acc >= delta)

    if (check == FALSE){
      except_ix <- c(except_ix, add_snps)
      max_noid <- max_noid + 1
      max_noid2 <- max_noid2 + 1
    } else {
      readc = readc + 1
      ms_out[[k]] <- c(acc_train, add_snps)
      train_ix <- c(train_ix, add_snps)
      t_add <- c(t_add, add_snps)
      train_itr_acc <- acc_train
      val_itr_acc = acc_val
      add_ix <- c(add_ix, add_snps)
      result_train_acc = c(result_train_acc, train_itr_acc)
      result_val_acc = c(result_val_acc, val_itr_acc)
      t_delta = result_train_acc[length(result_train_acc)] - result_train_acc[length(result_train_acc)-1]
      v_delta = result_val_acc[length(result_val_acc)] - result_val_acc[length(result_val_acc)-1]
      cat(paste0("Add: ", round(train_itr_acc,6)," (delta: ", round(t_delta, 6), ") train corr., ", round(val_itr_acc,6)," (delta: ", round(v_delta, 6), ") val corr., ", readc, " markers (", readcc, " reading), time: ", format(difftime(Sys.time(), s_time), usetz = TRUE), "\n", sep=""))
      max_noid <- 0
      max_noid2 <- 0
      r=0
      sel_snps <- init_selsnp
    }

    #(8-8) Setting nex iteration
    if (mm == "BTS"){
        i <- i + 1
    }

    if (mm == "RRB" ) {
        i <- i+1
    }
    k = k+1
    invisible(gc(verbose=FALSE, reset=TRUE, full=TRUE))
  }


  #(8-9) Saving and iteration result
  selected_train_acc = c(selected_train_acc, train_itr_acc)
  selected_val_acc = c(selected_val_acc, val_itr_acc)
  invisible(gc(verbose=FALSE, reset=TRUE, full=TRUE))
  cat(paste0("CV Number ", j, ": # of selected markers is ", length(train_ix), ", and correlation rates for train and validation are ", round(train_itr_acc,6), ', ', round(val_itr_acc,6), "\n"), sep="")
  cat(paste0("CV Number ", j, ": Running time for marker selection is ", format(difftime(Sys.time(), f_time), usetz = TRUE), "\n"),sep="")
  cat(paste0("CV Number ", j, ": End ", mm, " model."  ,"\n\n\n"), sep="")
  #tsum[[paste0("CV-", j, "_", mm)]] = format(difftime(Sys.time(), f_time), usetz = TRUE)
  tsum1 = format(difftime(Sys.time(), f_time), usetz = TRUE)

  CV_name = paste0("CV-", j, "_", mm)
  #CV_results[[CV_name]] = train_ix

  a <- plyr::ldply(ms_out, rbind)
  count <- length(which(!is.na(as.vector(a[1,-1]))))
  index <- count
  for (i in 2:nrow(a)){
    count <- count + length(which(!is.na(as.vector(a[i,-1]))))
    index <- c(index, count)
  }
  a <- data.frame(Index = index, a)
  colnames(a)[c(2,3)] <- c("Corr", "Marker")
  a$Corr <- as.numeric(as.vector(a$Corr))
  marker_save = paste0("CV-", j, "_", mm, ".MarkerList.log", sep="")
  write.table(a, file = marker_save, row.names = F, sep='\t', quote=F)
  sink(file = NULL)
  return(list("all_train_acc" = all_train_acc, "all_val_acc" = all_val_acc, selected_train_acc = selected_train_acc, selected_val_acc = selected_val_acc, CV_results = train_ix, nSamGenSum = nSamGen, tsum = tsum1, inisum = inisum1))
}
