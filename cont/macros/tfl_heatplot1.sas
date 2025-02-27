/*******************************************************************************
|
| Program Name   : tfl_heatplot1.sas
| Program Purpose: GTL Plot summarizing all the scenarios  
| SAS Version    : 9.4
| Created By     : Thomas Drury
| Date           : 04-08-20 
|
|--------------------------------------------------------------------------------
|
*******************************************************************************/

%macro heatplot1(indata=, inwhere=, t1=);

proc format lib = work; 
               
  value modelnum 0 = " " 
                 1 = "FULL"
                 2 = "MMRM"
                 3 = "CICS"
                 4 = "OICS"
                 5 = "OICS-R"
                 6 = "OIOS"
                 7 = "PICS"
                 8 = "PICS-R"
                 9 = "PIOS"
                 10 = " ";                 

run; 

*** CREATE LATTICE TITLE LABELS ***;
%sganno;
data annotate;

  %sgtext(x1=10, y1=100, x1space="graphpercent", y1space="graphpercent", width=50,
          label="&t1.", justify="left", anchor="top", rotate=0, textsize=11);
 
  %sgtext(x1=07, y1=91, x1space="graphpercent", y1space="graphpercent", width=50,
          label="Discontinuation Rate", justify="left", anchor="top", rotate=0, textsize=11);
  
  %sgtext(x1=18, y1=91, x1space="graphpercent", y1space="graphpercent", width=50, 
          label="With. Rate", justify="left", anchor="top", rotate=0, textsize=11);

  %sgtext(x1=26, y1=91, x1space="graphpercent", y1space="graphpercent", width=50, 
          label="With. Type", justify="left", anchor="top", rotate=0, textsize=11);

  %sgtext(x1=33, y1=91, x1space="graphpercent", y1space="graphpercent", width=50, 
          label="ID", justify="left", anchor="top", rotate=0, textsize=11);


run;

*** CREATE HEATPLOT TEMPLATE ***;
proc template;

  define statgraph heatplot1;
  begingraph / pad=0    
    designwidth  = 1200px 
    designheight = 800px
    backgroundcolor = white 
    border = false;


    rangeattrmap name="colorramp1";
      range -50 - -25  / rangecolormodel=( CXff4747 CXff6b6b );
      range -25 - 00   / rangecolormodel=( CXff6b6b white );
      range  00-25     / rangecolormodel=( white CX78aaff );
      range  25-50     / rangecolormodel=( CX78aaff CX4188ff );      
      range OTHER    / rangecolor=gray;                 
    endrangeattrmap;
    
    rangeattrmap name="colorramp2";
      range -25-00        /  rangecolormodel=( gold white );
      range  00-25        /  rangecolormodel=( white CXb2d8d8 );
      range  25-50        /  rangecolormodel=( CXb2d8d8 CX66b2b2 ); 
      range  50-75        /  rangecolormodel=( CX66b2b2 CX008080 );
      range  75-100       /  rangecolormodel=( CX008080 CX006666 );
      range OTHER         / rangecolor=gray;                 
    endrangeattrmap;

    rangeattrmap name="colorramp3";
      range -25 - -20        /  rangecolormodel=( CXff9b32 CXffa74c );
      range -20 - -15        /  rangecolormodel=( CXffa74c CXffb466 );
      range -15 - -10        /  rangecolormodel=( CXffb466 CXffc07f ); 
      range -10 - -05        /  rangecolormodel=( CXffc07f CXffcd99 );
      range -05 -  00        /  rangecolormodel=( CXffcd99 white );
      range OTHER         / rangecolor=gray;                 
    endrangeattrmap;
 
    rangeattrvar var=bias1 attrmap="colorramp1" attrvar=range_bias1;  
    rangeattrvar var=hw1 attrmap="colorramp2" attrvar=range_hw1;      
    rangeattrvar var=cic1  attrmap="colorramp3" attrvar=range_cic1;


    layout lattice / 
      pad             = 0
      rows            = 2 
      columns         = 7 
      rowdatarange    = union
      columndatarange = union
      rowgutter       = 1 
      columngutter    = 1
      rowweights      = (0.04 0.96)     
      columnweights   = (0.15 0.05 0.12 0.02 0.22 0.22 0.22);
 
      
      *** TABLE TITLE AREA - DISCONTINUATION RATES ***;
      layout gridded / pad=0 rows=1 order=columnmajor border=false;  
        entry halign=center " "  / textattrs=( size = 11pt );
      endlayout;
      
      *** TABLE TITLE AREA - WITHDRAWAL RATES ***;
      layout gridded / pad=0 rows=1 order=columnmajor border=false;  
        entry halign=center " "  / textattrs=( size = 11pt );
      endlayout;
      
      *** TABLE TITLE AREA - WITHDRAWAL TYPE ***;
      layout gridded / pad=0 rows=1 order=columnmajor border=false;  
        entry halign=center " "  / textattrs=( size = 11pt );
      endlayout;

      *** TABLE TITLE AREA - ID ***;
      layout gridded / pad=0 rows=1 order=columnmajor border=false;  
        entry halign=center " "  / textattrs=( size = 11pt );
      endlayout;
 
      *** BIAS TITLE AREA ***;
      layout gridded / pad=0 rows=1 order=columnmajor border=false;  
          entry halign=center "Bias (ml)"  / textattrs=( size = 11pt );
      endlayout;

      *** HW TITLE AREA ***;
      layout gridded / pad=0 rows=1 order=columnmajor border=false;  
          entry halign=center "Change in CI Halfwidth (%)"  / textattrs=( size = 11pt );
      endlayout;

      *** CIC TITLE AREA ***;
      layout gridded / pad=0 rows=1 order=columnmajor border=false;  
          entry halign=center "Change in CI Coverage (%)" / textattrs=( size = 11pt );
      endlayout;
        
       
      *** TEXT TABLE WITH ALL COMBINATIONS ***;
      layout overlay / pad=0 walldisplay=none 
      
        xaxisopts  = (display=none)
        x2axisopts = (display=none)
        
        yaxisopts  = (display=none reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)))
        y2axisopts = (display=none reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)));
           
        textplot    x = all y = case text = var_lbl1 / xaxis = x2 yaxis = y strip=true position=center textattrs=(size=8pt);

        referenceline y=0.5  / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=6.5  / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=12.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=18.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=24.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      

      endlayout;


      *** TEXT TABLE WITH ALL COMBINATIONS ***;
      layout overlay / pad=0 walldisplay=none
      
        xaxisopts  = (display=none)
        x2axisopts = (display=none)
        
        yaxisopts  = (display=none reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)))
        y2axisopts = (display=none reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)));
           
        textplot    x = all y = case text = var_lbl2 / xaxis = x2 yaxis = y strip=true position=center textattrs=(size=8pt);

        referenceline y=0.5  / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=03.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=06.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=09.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=12.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=15.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=18.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);             
        referenceline y=21.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=24.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      

      endlayout;

      *** TEXT TABLE WITH ALL COMBINATIONS ***;
      layout overlay / pad=0 walldisplay=none
      
        xaxisopts  = (display=none)
        x2axisopts = (display=none)
        
        yaxisopts  = (display=none reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)))
        y2axisopts = (display=none reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)));
           
        textplot    x = all y = case text = var_lbl3 / xaxis = x2 yaxis = y strip=true position=center textattrs=(size=8pt);

        referenceline y=0.5  / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=03.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=06.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=09.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=12.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=15.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=18.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);             
        referenceline y=21.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=24.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);       

      endlayout;

      *** TEXT TABLE WITH ALL COMBINATIONS ***;
      layout overlay / pad=0 walldisplay=none
      
        xaxisopts  = (display=none)
        x2axisopts = (display=none)
        
        yaxisopts  = (display=none reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)))
        y2axisopts = (display=none reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)));
           
        textplot    x = all y = case text = case / xaxis = x2 yaxis = y strip=true position=left textattrs=(size=8pt);

        referenceline y=0.5  / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=03.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=06.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=09.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=12.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=15.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=18.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);             
        referenceline y=21.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=24.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);         

      endlayout;

      *** BIAS HEATMAP WITH DATA TABLE ***; 
      layout overlay / pad=0 walldisplay = none
      
        xaxisopts  = (display=none )
        x2axisopts = (display=(ticks tickvalues) linearopts=(viewmin=1 viewmax=9 tickvaluesequence=(start=1 end=9 increment=1) TICKVALUEFITPOLICY=rotatealways tickvaluerotation=VERTICAL ) tickvalueattrs=(size=10pt))

        yaxisopts  = (display=(line) reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)))
        y2axisopts = (display=(line) reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)));
      
        heatmapparm x = modelnum y = case colorresponse = range_bias1 / xaxis=x2 name="heatmap1";
        textplot    x = modelnum y = case text = bias1 / xaxis=x2 position=center ;
         
        continuouslegend "heatmap1" / valueattrs=(size=8) valign=bottom;
  
        referenceline y=0.5  / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=03.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=06.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=09.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=12.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=15.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=18.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);             
        referenceline y=21.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=24.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);       
   
      endlayout;

      *** HW HEATMAP WITH DATA TABLE ***; 
      layout overlay / pad=0 walldisplay=none
      
        xaxisopts  = (display=none )
        x2axisopts = (display=(ticks tickvalues) linearopts=(viewmin=1 viewmax=9 tickvaluesequence=(start=1 end=9 increment=1) TICKVALUEFITPOLICY=rotatealways tickvaluerotation=VERTICAL) tickvalueattrs=(size=10pt))

        yaxisopts  = (display=(line) reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)))
        y2axisopts = (display=(line) reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)));
      
        heatmapparm x = modelnum y = case colorresponse = range_hw1 / xaxis=x2 name="heatmap2";
        textplot    x = modelnum y = case text = hw1 / xaxis=x2 position=center;
      
        continuouslegend "heatmap2" / valueattrs=(size=8) valign=bottom;

        referenceline y=0.5  / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=03.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=06.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=09.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=12.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=15.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=18.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);             
        referenceline y=21.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=24.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);       
      
      endlayout;

      *** CIC HEATMAP WITH DATA TABLE ***; 
      layout overlay / pad=0 walldisplay=none
      
        xaxisopts   = (display=none )
        x2axisopts  = (display=(ticks tickvalues) linearopts=(viewmin=1 viewmax=9 tickvaluesequence=(start=1 end=9 increment=1) TICKVALUEFITPOLICY=rotatealways tickvaluerotation=VERTICAL) tickvalueattrs=(size=10pt))

        yaxisopts  = (display=(line) reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)))
        y2axisopts = (display=(line) reverse=true linearopts=(viewmin=0.5 viewmax=24.5 tickvaluesequence=(start=1 end=24 increment=1)));
      
        heatmapparm x = modelnum y = case colorresponse = range_cic1 / xaxis=x2 name="heatmap3";
        
        textplot    x = modelnum y = case text = cic1 / xaxis=x2;
       
        continuouslegend "heatmap3" / valueattrs=(size=8) valign=bottom;

        referenceline y=0.5  / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=03.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=06.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=09.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=12.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=15.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=18.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);             
        referenceline y=21.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);      
        referenceline y=24.5 / yaxis=y2 lineattrs=(color = greyaa pattern = 1 thickness=0.5px);       
      
      endlayout;

    endlayout;
    
    annotate;   *** TELL SAS WHAT LEVEL TO APPLY THE ANNOTATE ***;

  endgraph;
  end;

run;
 
proc sgrender data     = &indata. 
              sganno   = annotate 
              template = heatplot1;
  &inwhere.;
  format modelnum modelnum.;
run;

%mend heatplot1;


