########## Part 3: Clustering and annotation ##########
#This part does clustering and annotation on highly multiplexed FISH data 

########## Prepare environment ##########
###Setting the working directory 
setwd("/mnt/khandler/R_projects/Sphere-sequencing/Highly_multiplexed_FISH_analysis/")

###Load packages and functions 
source("./functions_and_packages/1.Packages.R")
source("./functions_and_packages/2.Functions_ImageJ_connection.R")

###Load data 
#mets_samples = with visible metastasis, noMets_samples = no visible metastasis
mets_samples <- readRDS(file = "./data_files_generated/mets_QC_imageJcoordinate.rds")
noMets_samples <- readRDS(file = "./data_files_generated/noMets_QC_imageJcoordinate.rds")

mets_samples$samples <- "mets"
noMets_samples$samples <- "no_mets"

########## Merging and clustering ##########
#merge samples 
merged <- merge(mets_samples, noMets_samples)

merged <- FindVariableFeatures(merged, selction.method = "vst", nfeatures = 100)
all.genes <- rownames(merged)
merged <- ScaleData(merged,features = all.genes)
merged <- RunPCA(object = merged, features = VariableFeatures(object = merged),approx=FALSE)
ElbowPlot(merged)

#plot PCA space to check for batch effect 
DimPlot(merged, reduction = "pca", group.by = "Slide") #no batch effect 

merged <- FindNeighbors(object = merged, dims = 1:10, reduction = "pca")
merged <- FindClusters(merged, resolution = 1.5, random.seed = 2, algorithm = 1, graph.name = "originalexp_snn")
merged <- RunUMAP(merged, dims = 1:10, seed.use = 5, reduction = "pca")
DimPlot(merged, reduction = "umap", label = TRUE)

######### Annotation #########
DotPlot(merged, features = c(
          "Pglyrp1","Gpx2", #Metastasis 0,6,9
        "Cyp2e1","Cyp1a2" , #Hepatocytes CV 3,7,11,15,20,23
        "Fgb","Cyp2f2",  #Hepatocytes PV 1,4,14,21
        "Clec4f","Vsig4", #Kupffer cells 8
        "Lyz2","C1qc",#Monocytes 5
        "Csf3r", #Neutrophils 5 (more likely to be Monocytes)
        "Galnt15","Acer2","Pecam1",#LECs 2,10,19
        "App","Spp1",#Cholangiocytes 13,22
        "Tgfbi","Plvap","Lrat", #Stellate cells 12
        "Il2rb","Ccl5","Cd3d", #T cells 18
        "Cald1","Fn1", #Fibroblasts 17,24
        "Ighm","Itga4" #B cells 16
        )) + theme(axis.text.x = element_text(angle = 90))

current.cluster.ids <- c(0:24)
new.cluster.ids <- c("Metastasis","Hepatocytes_PV","LECs","Hepatocytes_CV","Hepatocytes_PV","Monocytes","Metastasis",
                     "Hepatocytes_CV","Kupffer","Metastasis","LECs","Hepatocytes_CV","Stellate",
                     "Cholangiocytes","Hepatocytes_PV","Hepatocytes_CV","B","Fibroblasts",
                     "T","LECs","Hepatocytes_CV","Hepatocytes_PV","Cholangiocytes","Hepatocytes_CV",
                     "Fibroblasts")
merged$annotation <- plyr::mapvalues(x = merged$seurat_clusters, from = current.cluster.ids, to = new.cluster.ids)
DimPlot(merged, reduction = "umap", label = TRUE, group.by = "annotation", label.size = 3)

########## plot Marker genes in DotPlot ##########
marker_genes <- c("Pglyrp1","Gpx2", #Metastasis
                  "Cyp2e1","Cyp1a2" , #Hepatocytes CV 
                  "Fgb","Cyp2f2",  #Hepatocytes PV
                  "Clec4f","Vsig4", #Kupffer cells
                  "Lyz2","C1qc",#Monocytes
                  "Galnt15","Acer2","Pecam1",#LECs
                  "App","Spp1",#Cholangiocytes
                  "Tgfbi","Plvap","Lrat", #Stellate cells
                  "Il2rb","Ccl5","Cd3d", #T cells
                  "Cald1","Fn1", #Fibroblasts
                  "Ighm","Itga4" #B cells
)

Idents(merged) <- "annotation"

p <- DotPlot(merged,features = marker_genes) + theme(axis.text.x = element_text(angle = 90)) + 
  ggtitle("Marker genes in annotation of Resolve data") + 
  theme(legend.title = element_text(size = 22), legend.text = element_text(size = 22)) + 
  theme(axis.title= element_text(size = 25)) + theme(axis.text = element_text(size = 15))+ 
  theme(plot.title = element_text(size = 25, face = "bold")) 
p + ggsave("./figures/3/marker_dotPlot.pdf",width = 12, height = 10)
p + ggsave("./figures/3/marker_dotPlot.svg",width = 12, height = 10)

########## plot annotated UMAP plots ##########
#colors: 
#Hepatocytes: CV #F46042 PV #56040C
#Kupffer cells: #E20FE8   
#LECs:  #F4E740
#Metastatic cells: #F90606
#Stellate cells: #C1A08A
#Fibroblasts: #8E5229 
#Cholangiocytes: #EDB2D4
#Monocytes: #19E80F 
#T cells: #2323E5 
#B cells: #EF975B

p <- DimPlot(merged, reduction = "umap", label = TRUE, group.by = "annotation", label.size = 3, cols = 
               c("#F90606","#56040C","#F4E740","#F46042",
                 "#19E80F","#E20FE8","#C1A08A","#EDB2D4" ,"#EF975B",
                 "#8E5229","#2323E5"), pt.size = 0.5) + theme(legend.title = element_text(size = 22), legend.text = element_text(size = 22)) + 
  theme(title = element_text(size = 25))+ theme(axis.text = element_text(size = 30)) 
p + ggsave("./figures/3/annotated_umap.pdf",width = 15, height = 10)
p + ggsave("./figures/3/annotated_umap.svg",width = 15, height = 10)

######### add vein and Mets_distance identity ##########
#combine the surrounding PV/CV and CV/PV to distal and Mets to proximal 
current.cluster.ids <- c("cv","cv_nm","cv_sm","mets","pv","pv_nm","pv_sm")
new.cluster.ids <- c("CV","CV","CV","Mets","PV","PV","PV")
merged$vein <- plyr::mapvalues(x = merged$spatial_feature, from = current.cluster.ids, to = new.cluster.ids)

current.cluster.ids <- c("cv","cv_nm","cv_sm","mets","pv","pv_nm","pv_sm")
new.cluster.ids <- c("distal","distal","distal","proximal","distal","distal","distal")
merged$Mets_distance <- plyr::mapvalues(x = merged$spatial_feature, from = current.cluster.ids, to = new.cluster.ids)

#change sample IDs depending on visible metastasis, mets..=visible metastasis; no_mets...=no visible metastasis 
current.cluster.ids <- c("Slide1_A1-1" ,"Slide1_A2-1"   ,"Slide1_A2-2"     ,"Slide1_B1-1" ,"Slide1_B1-2"  ,"Slide1_B2-1" )
new.cluster.ids <- c("metsA1","no_metsA2","no_metsA2","metsB1","metsB1","no_metsB2")
merged$sampleID <- plyr::mapvalues(x = merged$Slide, from = current.cluster.ids, to = new.cluster.ids)

###plot split UMAP plot 
p <- DimPlot(merged, reduction = "umap", label = TRUE, group.by = "annotation",split.by = "Mets_distance", label.size = 3, cols = 
               c("#F90606","#56040C","#F4E740","#F46042",
                 "#19E80F","#E20FE8","#C1A08A","#EDB2D4" ,"#EF975B",
                 "#8E5229","#2323E5"),pt.size = 0.5) + theme(legend.title = element_text(size = 22), legend.text = element_text(size = 22)) + 
  theme(title = element_text(size = 25))+ theme(axis.text = element_text(size = 30)) 
p + ggsave("./figures/3/annotated_umap_split_mets.pdf",width = 15, height = 10)
p + ggsave("./figures/3/annotated_umap_split_mets.svg",width = 15, height = 10)

######### check CV/PV manual drawing based on Hepatocyte landmark genes ##########
Idents(merged) <- "annotation"
hep <- subset(merged, idents = c("Hepatocytes_CV","Hepatocytes_PV"))
p <- DimPlot(hep,group.by = "annotation", split.by = "vein", cols = c("#56040C","#F46042"), pt.size = 0.5) + theme(legend.title = element_text(size = 22), legend.text = element_text(size = 22)) + 
  theme(title = element_text(size = 25))+ theme(axis.text = element_text(size = 30)) 
p + ggsave("./figures/3/split_plot_pv_cv_hep.pdf",width = 15, height = 10)
p + ggsave("./figures/3/split_plot_pv_cv_hep.svg",width = 15, height = 10)

########## save R object ########## 
saveRDS(merged,file = "./data_files_generated/Resolve_seurat_anno.rds")

########## Get annotation of cell types per slide and for each cell ##########
#this is used for the overlay with the Dapi image in ImageJ 
setwd("./data_files_generated/annotation_file_for_ImageJ")
Idents(merged) <- "Slide"

cell_types_mets <- c("Metastasis","Hepatocytes_CV","Kupffer","Monocytes","Hepatocytes_PV","LECs","Cholangiocytes",
                     "Stellate","T","Fibroblasts","B")
cell_types_noMets <- c("Hepatocytes_CV","Kupffer","Monocytes","Hepatocytes_PV","LECs","Cholangiocytes",
                       "Stellate","T","Fibroblasts","B")

A1_1 <- subset(merged, idents = "Slide1_A1-1")
Idents(A1_1) <- "annotation"
for (i in cell_types_mets) {
  text_file_generation_anno_resolve(A1_1,i,"^Slide1_A1-1_Cell","A1_1")
}

A2_1 <- subset(merged, idents = "Slide1_A2-1")
Idents(A2_1) <- "annotation"
for (i in cell_types_noMets) {
  text_file_generation_anno_resolve(A2_1,i,"^Slide1_A2-1_Cell","A2_1")
}

A2_2 <- subset(merged, idents = "Slide1_A2-2")
Idents(A2_2) <- "annotation"
for (i in cell_types_noMets) {
  text_file_generation_anno_resolve(A2_2,i,"^Slide1_A2-2_Cell","A2_2")
}

B1_1 <- subset(merged, idents = "Slide1_B1-1")
Idents(B1_1) <- "annotation"
for (i in cell_types_mets) {
  text_file_generation_anno_resolve(B1_1,i,"^Slide1_B1-1_Cell","B1_1")
}

B1_2 <- subset(merged, idents = "Slide1_B1-2")
Idents(B1_2) <- "annotation"
for (i in cell_types_mets) {
  text_file_generation_anno_resolve(B1_2,i,"^Slide1_B1-2_Cell","B1_2")
}

B2_1 <- subset(merged, idents = "Slide1_B2-1")
Idents(B2_1) <- "annotation"
for (i in cell_types_noMets) {
  text_file_generation_anno_resolve(B2_1,i,"^Slide1_B2-1_Cell","B2_1")
}

##per slide all cell types 
Idents(merged) <- "Slide"
merged_slides <- c("^Slide1_A1-1_Cell","^Slide1_A2-1_Cell","^Slide1_A2-2_Cell","^Slide1_B1-1_Cell",
                   "^Slide1_B1-2_Cell","^Slide1_B2-1_Cell")

slides_names <- as.data.frame(table(merged$Slide))$Var1

text_file_generation_per_slide_resolve(merged,"Slide1_A1-1","^Slide1_A1-1_Cell")
text_file_generation_per_slide_resolve(merged,"Slide1_A2-1","^Slide1_A2-1_Cell")
text_file_generation_per_slide_resolve(merged,"Slide1_A2-2","^Slide1_A2-2_Cell")
text_file_generation_per_slide_resolve(merged,"Slide1_B1-1","^Slide1_B1-1_Cell")
text_file_generation_per_slide_resolve(merged,"Slide1_B1-2","^Slide1_B1-2_Cell")
text_file_generation_per_slide_resolve(merged,"Slide1_B2-1","^Slide1_B2-1_Cell")


########## Subclustering of monocytes ##########
merged <- readRDS(file = "./data_files_generated/Resolve_seurat_anno.rds")

###subset monocytes
Idents(merged) <- "annotation"
mono <- subset(merged, idents = "Monocytes")

###cluster
mono <- FindVariableFeatures(mono, selction.method = "vst", nfeatures = 100)
all.genes <- rownames(mono)
mono <- ScaleData(mono,features = all.genes)
mono <- RunPCA(object = mono, features = VariableFeatures(object = mono),approx=FALSE)
ElbowPlot(mono)
mono <- FindNeighbors(object = mono, dims = 1:10, reduction = "pca")
mono <- FindClusters(mono, resolution = 0.2, random.seed = 2, algorithm = 4, graph.name = "originalexp_snn")
mono <- RunUMAP(mono, dims = 1:10, seed.use = 5, reduction = "pca")
DimPlot(mono, reduction = "umap", label = TRUE)

DotPlot(mono, features = c("Spp1","Dab2","C1qb","C1qc","Tgfbi","Lyz2","Il6ra","Tnfrsf1b"))
DimPlot(mono, group.by = "seurat_clusters",split.by = "Mets_distance")

###annotate 
current.cluster.ids <- c(1:3)
new.cluster.ids <- c("Mac_C1q","Mac_C1q","Mac_Ly6c")
mono$annotation <- plyr::mapvalues(x = mono$seurat_clusters, from = current.cluster.ids, to = new.cluster.ids)
DimPlot(mono, reduction = "umap", label = TRUE, group.by = "annotation", label.size = 3)

###splitplot between proximal and distal areas 
p <- DimPlot(mono, reduction = "umap", label = TRUE, pt.size = 2, group.by = "annotation",split.by = "Mets_distance",
             cols = c("#19E80F","#566B44")) + 
  theme(title = element_text(size = 25))+ theme(axis.text = element_text(size = 30)) +
  ggtitle("Annotation")
p + ggsave("./figures/3/Split_plot_mono.pdf", width = 15, height = 10)
p + ggsave("./figures/3/Split_plot_mono.svg", width = 15, height = 10)

###plot marker genes in annotated Dotplot 
###plot CV (Cyp2e1,"Cyp1a2) and PV (Cyp2f2,Alb) landmark genes in Dotplot 
Idents(mono) <- "annotation"
p <- DotPlot(mono, features = c("Spp1","Dab2","C1qb","C1qc","Tgfbi","Lyz2","Il6ra","Tnfrsf1b"), dot.scale = 20) + 
  theme(legend.title = element_text(size = 22), legend.text = element_text(size = 22)) + 
  theme(title = element_text(size = 25))+ theme(axis.text = element_text(size = 30)) +
  ggtitle("Landmark genes in monocytes")  +  theme(axis.text.x = element_text(angle = 90)) 
p + ggsave("./figures/3/mono_anno_dotplot.pdf",width = 12, height = 10)
p + ggsave("./figures/3/mono_anno_dotplot.svg",width = 12, height = 10)



