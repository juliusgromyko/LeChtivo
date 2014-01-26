; Article Data [Title, Text, Date, Author, Topic, Tags, Viewes, URL, FaceImage]
; Indexes [TAGs, Authors, Dates]

; Loading templates
Procedure.s ReadFileAsString(FileName.s)
  fileString.s=""
  f=ReadFile(#PB_Any,FileName)
  If f
    While Eof(f) = 0
     fileString=fileString+#CRLF$+ReadString(f)
    Wend
    CloseFile(f)
  EndIf
  
  ProcedureReturn fileString
EndProcedure

Global Template_Layout.s = ReadFileAsString("templates/layout")
Global Template_Index.s = ReadFileAsString("templates/index")
Global Template_Article.s = ReadFileAsString("templates/article")
Global Template_Article_Short.s = ReadFileAsString("templates/article_short")
Global Template_Ads.s = ReadFileAsString("templates/ads")
Global Template_About.s = ReadFileAsString("templates/about")
Global Template_TopNav.s
Global Template_BottomNav.s

; Global configs
Global URLPath_Articles_Index.s = "articles"
Global URLPath_TAGs_Index.s = "tag"
Global URLPath_Author_Index.s = "user"
Global URLPath_Date_Index.s = "date"
Global URLPath_TAGs_Icons.s = "img/topics"
Global URLPath_Article_Photos.s = "img/articles"
Global URLPath_ShowAll.s = "all"
Global Storage_TopicsList.s = "topics"
Global URLPage_SquareImages_Postfix.s = "_sq"
Global SquareImages_Size.i = 300
Global Article_ShortBodyText_Size.i = 500
Global Articles_Per_Index_Page.i=5

;{ TEMPLATE CODES
; {{TITLE}}
; {{CONTENT}}
; {{TOP_NAVIGATION}}
; {{BOTTOM_NAVIGATION}}
; {{BASE_URL}}
Procedure.s ReplaceCodes(layout.s, content.s, title.s="", baseUrl.s="")
  layout=ReplaceString(layout,"{{TOP_NAVIGATION}}",Template_TopNav)
  layout=ReplaceString(layout,"{{BOTTOM_NAVIGATION}}",Template_BottomNav)
  layout=ReplaceString(layout,"{{TITLE}}",title+" ")
  layout=ReplaceString(layout,"{{CONTENT}}",content)
  
  If baseUrl
    layout=ReplaceString(layout,"{{BASE_URL}}","<base href='"+baseUrl+"'>")
  Else
    layout=ReplaceString(layout,"{{BASE_URL}}","")
  EndIf

  ProcedureReturn layout
EndProcedure
;}

;{ TOPICS
Structure TAGs
  Name.s
  URL.s
  IconImage.s
  isMain.a
  PublicationsInTopic.i
EndStructure

Global NewList TAGsList.TAGs()

Procedure AddTAG(Name.s, URL.s, IconImage.s, isMain=#False)
  AddElement(TAGsList())
  TAGsList()\Name=Name
  TAGsList()\URL=URL
  TAGsList()\IconImage=IconImage
  TAGsList()\isMain = isMain
  TAGsList()\PublicationsInTopic = 0
EndProcedure

Procedure LoadTopics()
  f=ReadFile(#PB_Any,Storage_TopicsList)
    While Eof(f) = 0
      topicString.s=ReadString(f,#PB_UTF8)
      name.s = Trim(StringField(topicString,1,"|"))
      url.s = Trim(StringField(topicString,2,"|"))
      icon.s = Trim(StringField(topicString,3,"|"))
      ismain.a = #False : If Trim(StringField(topicString,4,"|"))="ShowOnMainNav" : ismain.a = #True : EndIf
      AddTAG(name, url, icon, ismain)
    Wend
  CloseFile(f)
EndProcedure

Procedure GenerateNavBasedOnTopics()
  ForEach TAGsList()
    If TAGsList()\isMain=#True
      topicURL.s=URLPath_TAGs_Index+"/"+TAGsList()\URL
      Template_TopNav=Template_TopNav+"<li class='cl-effect-2'><a href='"+topicURL+"'><span Data-hover='"+TAGsList()\Name+"'>"+TAGsList()\Name+"</span></a></li>"
      Template_BottomNav=Template_BottomNav+"<li class='cl-effect-2'><a href='"+topicURL+"'><span Data-hover='"+TAGsList()\Name+"'>"+TAGsList()\Name+"</span></a></li>"
    EndIf
  Next
EndProcedure

Procedure.s GetTAGIcon(TagName.s)
  ForEach TAGsList()
    If LCase(Trim(TAGsList()\Name))=LCase(Trim(TagName))
      ProcedureReturn TAGsList()\IconImage
    EndIf
  Next
EndProcedure

Procedure.s GetTAGURL(TagName.s)
  ForEach TAGsList()
    If LCase(Trim(TAGsList()\Name))=LCase(Trim(TagName))
      ProcedureReturn TAGsList()\URL
    EndIf
  Next
EndProcedure

Procedure.i isTAGMain(TagName.s)
  ForEach TAGsList()
    If LCase(Trim(TAGsList()\Name))=LCase(Trim(TagName))
      ProcedureReturn TAGsList()\isMain
    EndIf
  Next
EndProcedure

LoadTopics()
GenerateNavBasedOnTopics()
;}

;{ ARTICLES

Structure Article
  Title.s
  URL.s
  Author.s
  AuthorURL.s
  Date.s
  CoverImage.s
  MainTopic.s
  SubTopics.s
  Body.s
EndStructure

Global NewList Articles.Article()

Procedure LoadArticle(file.s)
  f=ReadFile(#PB_Any,file)
  If f
    isBody=0
    AddElement(Articles())
    
    While Eof(f) = 0
      fileString.s=ReadString(f)
      
      If isBody ; Если считываем тело статьи
        Articles()\Body=Articles()\Body+fileString
      Else
        tag.s=LCase(Trim(StringField(fileString,1,"=")))
        subTag.s=Trim(StringField(fileString,2,"="))
        Select tag
          Case "[body]"
            isBody=1
          Case "title"
            Articles()\Title=subTag
          Case "url"
            Articles()\URL=subTag
          Case "author"
            authorName.s=Trim(StringField(subTag,2,"}"))
            authorURL.s=Trim(ReplaceString(StringField(subTag,1,"}"),"{",""))
            Articles()\Author=authorName
            Articles()\AuthorURL=authorURL
          Case "date"
            Articles()\Date=subTag
          Case "cover_image"
            Articles()\CoverImage=URLPath_Article_Photos+"/"+subTag
          Case "main_topic"
            Articles()\MainTopic=subTag
          Case "sub_topics"
            Articles()\SubTopics=subTag
          Default  
        EndSelect
      EndIf
    Wend
    CloseFile(f)
  EndIf
EndProcedure

Procedure LoadAllArticles()
  d=ExamineDirectory(#PB_Any,"articles","*")
  If d 
    While NextDirectoryEntry(d)
      If DirectoryEntryType(d) = #PB_DirectoryEntry_File And DirectoryEntryName(d) <>".DS_Store"
        LoadArticle("articles/"+DirectoryEntryName(d))
      EndIf
    Wend
    FinishDirectory(d)
  EndIf
  
  SortStructuredList(Articles(),#PB_Sort_Descending,OffsetOf(Article\Date),#PB_String)
EndProcedure

Procedure.s GenerateSubTagLine(*Article.Article)
  subLine.s=""
  
  For t=1 To CountString(*Article\SubTopics,",")+1
    topic.s=Trim(StringField(*Article\SubTopics,t,","))
    subLine=subLine+"<dd><a href='"+URLPath_TAGs_Index+"/"+GetTAGURL(topic)+"'>"+topic+"</a></dd>"
  Next
  
  ProcedureReturn subLine
EndProcedure

Procedure.s GenerateShortBodyText(*Article.Article)
  e=FindString(*Article\Body,".",Article_ShortBodyText_Size-100)
  If e>0
    ShortBody.s=Left(*Article\Body,e)
  Else
    ShortBody.s=Left(*Article\Body,Article_ShortBodyText_Size)
  EndIf
  
  ProcedureReturn ShortBody
EndProcedure

Procedure.s ReplaceArticleRelatedCodes(Layout.s, *Article.Article)
  Article_Layout.s=Layout
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_URL}}",URLPath_Articles_Index+"/"+*Article\URL)
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_TAG_ICON}}",URLPath_TAGs_Icons+"/"+GetTAGIcon(*Article\MainTopic))
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_TAG_NAME}}",*Article\MainTopic)
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_TAG_URL}}",URLPath_TAGs_Index+"/"+GetTAGURL(*Article\MainTopic))
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_COVER_PHOTO}}",*Article\CoverImage)
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_COVER_PHOTO_SQUARE}}",StringField(*Article\CoverImage,1,".")+URLPage_SquareImages_Postfix+".jpg")
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_AUTHOR}}",*Article\Author)
  ;Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_AUTHOR_URL}}",URLPath_Author_Index+"/"+*Article\AuthorURL)
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_AUTHOR_URL}}","#")
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_DATE}}",*Article\Date)
  ;Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_DATE_URL}}",URLPath_Date_Index+"/"+*Article\Date)
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_DATE_URL}}","#")
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_TITLE}}",*Article\Title)
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_BODY}}",*Article\Body)
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_SHORT_BODY}}",GenerateShortBodyText(*Article.Article))
  Article_Layout = ReplaceString(Article_Layout,"{{ARTICLE_TAG_LINE}}",GenerateSubTagLine(*Article))
  
  ; SIMILAR ARTICLES
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_URL_1}}",URLPath_Articles_Index+"/"+*Article\URL)
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_IMAGE_SQ_1}}",StringField(*Article\CoverImage,1,".")+URLPage_SquareImages_Postfix+".jpg")
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_TITLE_1}}",*Article\Title)
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_URL_2}}",URLPath_Articles_Index+"/"+*Article\URL)
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_IMAGE_SQ_2}}",StringField(*Article\CoverImage,1,".")+URLPage_SquareImages_Postfix+".jpg")
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_TITLE_2}}",*Article\Title)
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_URL_3}}",URLPath_Articles_Index+"/"+*Article\URL)
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_IMAGE_SQ_3}}",StringField(*Article\CoverImage,1,".")+URLPage_SquareImages_Postfix+".jpg")
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_TITLE_3}}",*Article\Title)
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_URL_4}}",URLPath_Articles_Index+"/"+*Article\URL)
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_IMAGE_SQ_4}}",StringField(*Article\CoverImage,1,".")+URLPage_SquareImages_Postfix+".jpg")
  ; Article_Layout = ReplaceString(Article_Layout,"{{SIMILAR_ARTICLE_TITLE_4}}",*Article\Title)
  
  ProcedureReturn Article_Layout
EndProcedure

Procedure.s GenerateArticleLayout(*Article.Article)
  Article_Layout.s=Template_Article
  
  ; Replace Article Specific info
  Article_Layout = ReplaceArticleRelatedCodes(Article_Layout, *Article)
  
  ; PROMO SECTION
  ; Article_Layout = ReplaceString(Article_Layout,"{{PROMO_SQUARE_TITLE_1}}",*Article\Title)
  ; Article_Layout = ReplaceString(Article_Layout,"{{PROMO_SQUARE_URL_1}}",URLPath_Articles_Index+"/"+*Article\URL)
  ; Article_Layout = ReplaceString(Article_Layout,"{{PROMO_SQUARE_IMAGE_1}}",StringField(*Article\CoverImage,1,".")+URLPage_SquareImages_Postfix+".jpg")
  ; Article_Layout = ReplaceString(Article_Layout,"{{PROMO_SQUARE_TITLE_2}}",*Article\Title)
  ; Article_Layout = ReplaceString(Article_Layout,"{{PROMO_SQUARE_URL_2}}",URLPath_Articles_Index+"/"+*Article\URL)
  ; Article_Layout = ReplaceString(Article_Layout,"{{PROMO_SQUARE_IMAGE_2}}",StringField(*Article\CoverImage,1,".")+URLPage_SquareImages_Postfix+".jpg")
  
  Article_Layout=ReplaceCodes(Template_Layout, Article_Layout, *Article\Title+" – ","../")
  
  ProcedureReturn Article_Layout
EndProcedure

;}

;{ PHOTOS
UseJPEGImageDecoder()
UseJPEGImageEncoder()

Procedure GenerateSquareCoverImages()
  ForEach Articles()
    img_name.s = "static/"+Articles()\CoverImage
    img_sq_name.s = StringField(img_name.s,1,".")+URLPage_SquareImages_Postfix+".jpg"
    
    f=ReadFile(#PB_Any,img_sq_name)
    If f : CloseFile(f) : Else
      img = LoadImage(#PB_Any,img_name)
      newWidth=ImageWidth(img)*(SquareImages_Size+50)/ImageHeight(img)
      newHeight=SquareImages_Size+50
      ResizeImage(img,newWidth,newHeight,#PB_Image_Smooth)
      img_sq=GrabImage(img,#PB_Any,(newWidth-SquareImages_Size)/2,0,SquareImages_Size,SquareImages_Size)
      FreeImage(img)
      SaveImage(img_sq,img_sq_name,#PB_ImagePlugin_JPEG)
      FreeImage(img_sq)
    EndIf
  Next
EndProcedure
;}

;{ BUILD PROCS

Procedure SaveLayoutAsFile(file.s,layout.s)
  DeleteFile(file,#PB_FileSystem_Force)
  
  f = OpenFile(#PB_Any,file)
  WriteString(f,layout)
  CloseFile(f)  
EndProcedure

Procedure.s ReplaceIndexCodes(layout.s, prevPageURL.s="", NextPageUrl.s="",pageNum.i=0)
  
  ; TOPIC LIST
  topicList.s=""
  For t=0 To ListSize(TAGsList())-1
    SelectElement(TAGsList(),t)
    topicList = topicList + "<a href='"+URLPath_TAGs_Index+"/"+TAGsList()\URL+"'>"+TAGsList()\Name+"</a>"
    If t<ListSize(TAGsList())-1
      topicList = topicList + " – "
    EndIf
  Next
  layout=ReplaceString(layout,"{{POPULAR_TOPICS}}",topicList)
  
  ; PAGINATOR
  code.s=""
  
  If prevPageURL=""
    code=code+"<li class='arrow unavailable'><a href=''>&laquo;</a></li>"
  Else
    code=code+"<li class='arrow'><a href='"+prevPageURL+"'>&laquo;</a></li>"
  EndIf
  
  code=code+"<li class='unavailable'><a href=''>&hellip;</a></li>"
  If pageNum
    code=code+"<li class='current'><a href=''>"+Str(pageNum)+"</a></li>"
    code=code+"<li class='unavailable'><a href=''>&hellip;</a></li>"
  EndIf
  
  If NextPageUrl=""
    code=code+"<li class='arrow unavailable'><a href=''>&raquo;</a></li>"
  Else
    code=code+"<li class='arrow'><a href='"+NextPageUrl+"'>&raquo;</a></li>"
  EndIf
              
  layout=ReplaceString(layout,"{{PAGINATOR}}",code)
              
  ProcedureReturn layout
EndProcedure

Procedure GenerateArticleIndex(BuildPath.s, Tag.s="", filename.s="")
  If tag
    path.s=buildPath+"/"+URLPath_TAGs_Index+"/"
    shortPath.s=URLPath_TAGs_Index+"/"
    filename.s=filename
  Else
    path.s=buildPath
    shortPath.s=""
    filename.s="index"
  EndIf
  splitpages=Articles_Per_Index_Page
  
  onpage=0
  pageNum=1
  IndexContent.s=""
  ForEach Articles()
    If (Tag<>"" And (FindString(Articles()\MainTopic,Tag) Or FindString(Articles()\SubTopics,Tag))) Or (Tag="others" And isTAGMain(Articles()\MainTopic)=#False) Or tag=""
      IndexContent=IndexContent+ReplaceArticleRelatedCodes(Template_Article_Short, Articles())      
      onpage=onpage+1
      
      ; Save page when times come
      If onpage>=splitpages
        If Tag
          layout_tmp.s=ReplaceCodes(Template_Layout, ReplaceString(Template_Index,"{{ARTICLE_INDEX}}",IndexContent), "Публикации по теме "+Tag,"../")
        Else
          layout_tmp.s=ReplaceCodes(Template_Layout, ReplaceString(Template_Index,"{{ARTICLE_INDEX}}",IndexContent))
        EndIf
        
        If pageNum=1
          ; Updating paginator
          layout_tmp=ReplaceIndexCodes(layout_tmp, "", shortPath+filename+Str(pageNum+1),pageNum)
          
          SaveLayoutAsFile(path+"/"+filename,layout_tmp)
        Else
          ; Updating paginator
          If pageNum=2
            layout_tmp=ReplaceIndexCodes(layout_tmp, shortPath+filename, shortPath+filename+Str(pageNum+1), pageNum)
          Else
            layout_tmp=ReplaceIndexCodes(layout_tmp, shortPath+filename+Str(pageNum-1), shortPath+filename+Str(pageNum+1), pageNum)
          EndIf
          
          SaveLayoutAsFile(path+"/"+filename+Str(pageNum),layout_tmp)
        EndIf
        
        pageNum=pageNum+1
        onpage=0
        IndexContent=""
      EndIf
      
    EndIf
  Next
  
  ; Save last page
  If onpage=0
    IndexContent="<h5 class='text-center'>Пока публикаций по этой теме нету</h5><br>"
  EndIf
  
  If Tag
    layout_tmp.s=ReplaceCodes(Template_Layout, ReplaceString(Template_Index,"{{ARTICLE_INDEX}}",IndexContent), "Публикации по теме "+Tag,"../")
  Else
    layout_tmp.s=ReplaceCodes(Template_Layout, ReplaceString(Template_Index,"{{ARTICLE_INDEX}}",IndexContent))
  EndIf
  
  ; Updating paginator
  If pageNum=1
    If onpage=0
      layout_tmp=ReplaceIndexCodes(layout_tmp, "","", 0)
    Else
      layout_tmp=ReplaceIndexCodes(layout_tmp, "","", pageNum)
    EndIf
  ElseIf pageNum=2
    layout_tmp=ReplaceIndexCodes(layout_tmp, shortPath+filename, "", pageNum)
  Else
    layout_tmp=ReplaceIndexCodes(layout_tmp, shortPath+filename+Str(pageNum-1), "",pageNum)
  EndIf
  
  If pageNum=1
    SaveLayoutAsFile(path+"/"+filename,layout_tmp)
  Else
    SaveLayoutAsFile(path+"/"+filename+Str(pageNum),layout_tmp)
  EndIf
EndProcedure

Procedure GenerateArticleIndexForTags(BuildPath.s)
  For t=0 To ListSize(TAGsList())-1
    SelectElement(TAGsList(),t)
    GenerateArticleIndex(BuildPath,TAGsList()\Name, TAGsList()\URL)
  Next
EndProcedure

Procedure CreateNewBuild()
  LoadAllArticles()
  GenerateSquareCoverImages()
  
  buildPath.s="builds/build "+FormatDate("%yyyy-%mm-%dd %hh-%ii-%ss",Date())
  CreateDirectory(buildPath)
  
  CopyDirectory("static",buildPath,"*",#PB_FileSystem_Recursive|#PB_FileSystem_Force)
  
  ; Generating ADS page
  SaveLayoutAsFile(buildPath+"/"+"ads",ReplaceCodes(Template_Layout, Template_Ads, "Реклама на сайте "))

  ; Generating ABOUT page
  SaveLayoutAsFile(buildPath+"/"+"about",ReplaceCodes(Template_Layout, Template_About, "О сайте "))
  
  ; Generating ARTICLES pages
  ForEach Articles()
    SaveLayoutAsFile(buildPath+"/"+URLPath_Articles_Index+"/"+Articles()\URL,GenerateArticleLayout(@Articles()))
  Next
  
  ; Generating TAG indexes
  GenerateArticleIndexForTags(buildPath)
  
  ; Generate FULL page indexes
  GenerateArticleIndex(buildPath)
  
EndProcedure

;}

CreateNewBuild()
; IDE Options = PureBasic 5.20 beta 19 LTS (MacOS X - x86)
; CursorPosition = 98
; FirstLine = 37
; Folding = IBAA+
; EnableUnicode
; EnableThread
; EnableXP
; Executable = StaticGenerator.app