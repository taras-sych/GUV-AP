



//---------Data input--------------
ce = 1.2;
alpha_step = 6;

image_title = getTitle;

oops = true;
while (oops == true){

	Dialog.create("Parameters");
	Dialog.addChoice("protein channel", newArray(1,2));
	Dialog.addNumber("threshold:", 0.1);
	Dialog.show();
	prot_chan = Dialog.getChoice();
	tc = Dialog.getNumber();
	user_is_happy = "NO";

	dir = getDirectory("image"); 
	rename ("raw_data");

	getPixelSize(unit, pixelWidth, pixelHeight);

	run("Duplicate...", "title=raw_data_1 duplicate");
	run("Split Channels");

	if (prot_chan == "1.0"){
		selectWindow("C2-raw_data_1");
		rename ("membrane_0");

		selectWindow("C1-raw_data_1");
		rename("LecA_0");
	}
		
	if (prot_chan == "2.0"){
		selectWindow("C1-raw_data_1");
		rename ("membrane_0");

		selectWindow("C2-raw_data_1");
		rename("LecA_0");
	}

	selectWindow ("LecA_0");
	run("Smooth");
	run("Smooth");
	run("Smooth");
	run("Smooth");
			
	while (user_is_happy == "NO"){
		
		if (roiManager("count")>0){
			run("Select None");
			roiManager("Deselect");
			roiManager("Delete");
		}

	selectWindow("membrane_0");
	run("Duplicate...", "title=membrane");

	selectWindow ("membrane");

	run("Set Measurements...", "mean min redirect=None decimal=3");
	run("Measure");

	top = getResult("Max",0);
	bottom = (top - getResult("Min",0)) * tc + getResult("Min",0);

	run("Clear Results");
	selectWindow ("membrane");
	setAutoThreshold("Default dark");
	setThreshold(bottom, top);


	setOption("BlackBackground", false);
	run("Make Binary");

	run("Invert LUT");

	run("Set Measurements...", "area centroid bounding shape redirect=None decimal=3");
	run("Analyze Particles...", "size=20-Infinity pixel display exclude clear add in_situ");
	
	Dialog.create("");
	Dialog.addChoice("Happy?", newArray("YES","NO"));
	
	Dialog.addNumber("bottom:", tc);
	Dialog.addCheckbox("OOPS", false);
	Dialog.show();
	user_is_happy = Dialog.getChoice();
	tc = Dialog.getNumber();
	oops = Dialog.getCheckbox();

	if (user_is_happy == "NO" && oops == false){

		if (roiManager("count")>0){
			roiManager("Deselect");
			roiManager("Delete");
			}
			run("Clear Results");

			selectWindow("membrane");
			close();

			selectWindow("LecA");
			close();
		
		}

	if (oops == true){
			
		if (roiManager("count")>0){
			roiManager("Deselect");
			roiManager("Delete");
			run("Clear Results");
		}
		user_is_happy = "YES";


	
		selectWindow("membrane");
		close();

		selectWindow("membrane_0");
		close();

		selectWindow("LecA_0");
		close();
	}
	}//end of while user happy
}//end of while oops

roiManager("Deselect");
roiManager("Delete");


//---------Array initialization-----

N = nResults;
R = newArray (nResults);
x_c = newArray (nResults);
y_c = newArray (nResults);
interface = newArray (nResults);
binding = newArray (nResults);
no_binding = newArray (nResults);
ratio = newArray (nResults);

//----------------------------------


for (i=0; i<nResults; i++){

	GUV_name = "GUV_" + i;
	
	x_c [i] = getResult("X",i);
	y_c [i] = getResult("Y", i);

	width = getResult("Width", i);
	height = getResult("Height", i);

	R [i] = (width+height)/4 * ce;
	makeOval ((x_c [i] - R [i])/pixelWidth, (y_c [i] - R [i])/pixelWidth, 2*R [i]/pixelWidth, 2*R [i]/pixelWidth);
	roiManager("Add");
	
}

selectWindow("membrane");
close();

//---------------------------------Save the output-----------------------



getDateAndTime(year, month, dayofWeek, dayofMonth, hour, minute, second, msec);

dir1 =  dir + " " + year +"." + month + "." + dayofMonth + " " + hour + "." + minute + "\\" ;
File.makeDirectory(dir1);




selectWindow("raw_data");
run("Duplicate...", "title=raw_data_1 duplicate");
roiManager("Show None");
roiManager("Show All");



file_marked = dir1 + File.separator + image_title;

saveAs("Tiff", file_marked);
close();


roiManager("Deselect");
roiManager("Delete");
run("Clear Results");

selectWindow("LecA_0");

run("Set Measurements...", "mean redirect=None decimal=3");
run("Measure");

bottom = getResult("Mean", 0);

run ("32-bit");
setThreshold(bottom, 4096);
run("NaN Background", "stack");

/*
setTool("rectangle");
waitForUser( "Pause","Please, select protein background area");
run("Set Measurements...", "mean redirect=None decimal=3");
run("Measure");
			
background = getResult("Mean", 0);
run("Clear Results");
*/

n_points = 360/alpha_step;

Profile_array = newArray(n_points);

	Dialog.create("What to calculate:");
	Dialog.addChoice( "Calculatio", newArray ("Interface sizes", "Signal ratio"));
	Dialog.show();
	Task = Dialog.getChoice();


//-------------------------Define thresholds------------------------------------

if (Task ==  "Interface sizes"){
	selectWindow ("LecA_0");
	waitForUser("Define threshold of non-interface");
	Dialog.create("Interface thresholds:");
	Dialog.addNumber("GUV bottom:", 395);
	Dialog.show();
	bottom = Dialog.getNumber();


	
	selectWindow ("LecA_0");
	setThreshold(bottom, 65535);
	run("Convert to Mask");
	run("32-bit");
	
	setThreshold(100, 255);
	run("NaN Background");
	setAutoThreshold("Default");
	
	
}



//-------------------------------------------------------------------------------

if (Task ==  "Interface sizes"){
xl=File.open(dir1+ File.separator+"Interface sizes.xls");
print(xl,"number of GUV" + "\t\t" + "Radius" + "\t\t" + "Interface1" + "\t\t" + "Interface2" + "\t\t" + "Interface3" + "\t\t" + "Interface4" + "\t\t" + "Interface5" + "\t\t" + "Interface6" + "\t\t" + "Interface7");
}

for (i = 0; i<N; i++){

	ratio [i] = 0;

	

	for (alpha = alpha_step; alpha<=360; alpha=alpha + alpha_step){
		x_1 = x_c [i] + R [i] *sin(alpha*PI/180);
			y_1 = y_c [i] + R [i]*cos(alpha*PI/180);

			x_2 = x_c [i] + R [i]*sin((alpha + alpha_step)*PI/180);
			y_2 = y_c [i] + R [i]*cos((alpha + alpha_step)*PI/180);

			makePolygon(x_c [i]/pixelWidth,y_c [i]/pixelWidth,x_1/pixelWidth,y_1/pixelWidth,x_2/pixelWidth,y_2/pixelWidth);

			run("Set Measurements...", "mean min redirect=None decimal=3");
			run("Measure");
			value = getResult("Mean", 0);


			Profile_array[(alpha-alpha_step)/alpha_step] = value;

			run("Clear Results");
	}//end of alpha cycle

if (Task ==  "Signal ratio"){
	sum = 0;
	
	for (j=0; j<lengthOf(Profile_array); j++)
		sum = sum + Profile_array[j];

	average = sum/lengthOf(Profile_array);


	count_i = 0;
	count_s = 0;

	value_i = 0;
	value_s = 0;
	
	for (j=0; j<lengthOf(Profile_array); j++){

		if (Profile_array[j] > average){
			value_i = value_i + Profile_array[j];
			count_i ++;
		}

		if (Profile_array[j] < average){
			value_s = value_s + Profile_array[j];
			count_s ++;
		}
	}

	value_ratio = (value_i/count_i)/(value_s/count_s);

	ratio [i] = value_ratio;
}

if (Task ==  "Interface sizes"){

	
	j = 0;
	int_array = newArray;

	while (j<lengthOf(Profile_array)){

		int_counter = 0;

		if (Profile_array[j] != Profile_array[j]){

			
			
			while (Profile_array[j] != Profile_array[j] && j< (lengthOf(Profile_array)-1)){
				int_counter ++;
				j++;
			}
			int_array = Array.concat(int_array,int_counter);
		}



		j++;
		
	}

	if (lengthOf (int_array) == 0){
		int_array = Array.concat(int_array,0);
	}

	line = "GUV " + i+1 + "\t\t" + R[i] + "\t\t";

	for (j=0; j<lengthOf(int_array); j++){
		line = line + "\t\t" + int_array[j] * alpha_step;
	}

	print(xl, line);
	
}
	
}//end of calculation cycle

File.close(xl);





if (Task ==  "Signal ratio"){

xl=File.open(dir1+ File.separator+"Summary.xls");

print(xl,"number of GUV" + "\t\t" + "ratio");

for (i = 0; i<N; i++){
	print(xl, i+1 + "\t\t" + ratio [i]);
}

File.close(xl);
}

ScreenClean();

function ScreenClean()
      {	
	while (nImages>0) close();

          WinOp=getList("window.titles");
	for(i=0; i<WinOp.length; i++)
	  {selectWindow(WinOp[i]);run ("Close");}

	  fenetres=newArray("B&C","Channels","Threshold");
	for(i=0;i!=fenetres.length;i++)
	   if (isOpen(fenetres[i]))
	    {selectWindow(fenetres[i]);run("Close");}
       }
