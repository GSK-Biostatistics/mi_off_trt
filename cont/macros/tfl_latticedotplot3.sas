/*******************************************************************************
|
| Program Name   : tfl_latticedotplot3.sas
| Program Purpose: GTL Plot of Discontinuation Rate vs Withdrawal Type  
| SAS Version    : 9.4
| Created By     : Thomas Drury
| Date           : 04-08-20 
|
|--------------------------------------------------------------------------------
|
*******************************************************************************/

%macro latticedotplot3(indata  =
                     ,inwhere = 
                     ,xvar    = 
                     ,yvar    = 
                     ,ylower  = 
                     ,yupper  =
                     ,ytvar   =
                     ,ytlabel = 
                     ,yref    =
                     ,zvar    = 
                     ,xmin    = 
                     ,xmax    = 
                     ,xby     = 
                     ,ymin    = 
                     ,ymax    = 
                     ,yby     = 
                     ,xformat =
                     ,ylabel  = 
                     ,dsize   = 8
                     ,ttxt1   = 
                     ,ttxt2   = 
                     ,ttxt3   =
                     ,ttxt4   =
                     ,ttxt5   =
                     ,ftxt1   =);


*** CREATE FORMATS ***;
proc format lib = work;
                                    
  value discrate 1 = "10% Control 10% Active"
                 2 = "10% Control 20% Active"
                 3 = "20% Control 20% Active"
                 4 = "50% Control 50% Active";
  
  value withtype 1 = "More Early"
                 2 = "Balanced"
                 3 = "More Late";

quit;
run;


*** CREATE LATTICE TITLE LABELS ***;
%sganno;
data annotate;
  %sgtext(x1=96, y1=50, x1space="graphpercent", y1space="graphpercent", width=50,
          label="Study Withdrawal Type", justify="left", anchor="top", rotate=90, textsize=14);
  %sgtext(x1=50, y1=98, x1space="graphpercent", y1space="graphpercent", width=50, 
          label="Treatment Discontinuation Rate", justify="left", anchor="top", rotate=0, textsize=14);
run;


*** CREATE LATTICE STRUCTURE TEMPLATE ***;
proc template;
  
  define statgraph latticeplot3;

   dynamic XVAR XMIN XMAX XBY   
           YVAR YMIN YMAX YBY YLABEL   
           ZVAR 
           %if %length(&ylower.) ne 0 %then %do; YLOWER %end;
           %if %length(&yupper.) ne 0 %then %do; YUPPER %end;     
           %if %length(&ytvar.) ne 0 %then %do; YTVAR YTLABEL %end;
           ;

   begingraph /  pad=(top=8pct right=8pct)   
      designwidth  = 800px 
      designheight = 600px
      backgroundcolor = white 
      border = true
      borderattrs = (color=greyaa)
      datacolors  =( black red mediumblue forestgreen)
      datacontrastcolors = ( black red mediumblue forestgreen);
         
      layout datalattice rowvar=withtype columnvar=discrate / 
        
        headerlabeldisplay=value
        headerbackgroundcolor=white
        headerlabelattrs=(size=11)
        headerborder=false

        rows = 3
        rowdatarange = union
        rowaxisopts=(display=all griddisplay=on label=YLABEL
          linearopts=(viewmin=YMIN viewmax=YMAX tickvaluesequence=(start=YMIN end=YMAX increment=YBY) minorgrid=on))

        columns = 4
        columndatarange = union 
        columnaxisopts=(display=(line ticks tickvalues) griddisplay=on 
          linearopts=(viewmin=XMIN viewmax=XMAX 
                      tickvaluesequence  = (start=XMIN end=XMAX increment=XBY) 
                      tickvaluefitpolicy = rotatealways
                      tickvaluerotation  = diagonal2));

  
        layout prototype;

          %if %length(&yref.) ne 0 %then %do; referenceline y = &yref. / lineattrs=(color=darkgrey pattern=3); %end;   

          scatterplot x = XVAR y = YVAR  / group = ZVAR
            %if %length(&ylower.) ne 0 %then %do; yerrorlower = YLOWER %end; 
            %if %length(&yupper.) ne 0 %then %do; yerrorupper = YUPPER %end;
            markerattrs = (symbol=circlefilled size=&dsize.);
            
            %if %length(&ytvar.) ne 0 %then %do;
              scatterplot x = XVAR y = YTVAR / group = ZVAR datalabel = YTLABEL datalabelposition=top
                markerattrs=(symbol=triangledown size=&dsize. weight=bold)
                datalabelattrs=(weight=bold);
            %end; 
            
        endlayout;
    
      endlayout;
          
      annotate;    
          
    endgraph;
  
  end;
  
run;
    
    
*** CREATE PLOT ***;
title1 j=c "&ttxt1.";
title2 j=c "&ttxt2.";
title3 j=l "&ttxt3.";
title4 j=l "&ttxt4.";
title5 j=l "&ttxt5.";
footnote1 j=l "&ftxt1.";

proc sgrender data=&indata. sganno=annotate template=latticeplot3;
  
  &inwhere.;
  
  dynamic XVAR="&xvar." XMIN="&xmin." XMAX="&xmax." XBY="&xby."
          YVAR="&yvar." YMIN="&ymin." YMAX="&ymax." YBY="&yby."
          YLABEL="&ylabel."  
          ZVAR="&zvar."
          %if %length(&ylower.) ne 0 %then %do; YLOWER="&ylower." %end;
          %if %length(&yupper.) ne 0 %then %do; YUPPER="&yupper." %end;        
          %if %length(&ytvar.) ne 0 %then %do; YTVAR="&ytvar." YTLABEL="&ytlabel." %end;
          ;
 
  format discrate discrate. withtype withtype. &xvar. &xformat..;
run;    
title1;    
title2;    
title3;    
title4;
title5;
footnote1;
     
%mend;    
    
    
