// the Javascript file for vnStatsvg

var vnstat_cgibin="/cgi-bin/";
var vnstat_admin="./";

var vnstat_proxy=vnstat_cgibin+"proxy.sh";
var sidebar_xsl=vnstat_admin+"sidebar.xsl";
var sidebar_xml=vnstat_admin+"sidebar.xml";
var vnstat_xml="";	/* here we will use the CGI program to generate the dynamical XML file */
var vnstat_xsl=vnstat_admin+"vnstat.xsl";

var xmlHttp;
var xmlFile;
var xslFile;
var divID;
var speed = 1000;
var alertTimerId = 0;

function showSidebar()
{
	divID="sidebar"; xmlFile=sidebar_xml; xslFile=sidebar_xsl;
	showXML();
}

function showPage(page, caption)
{
	states = getHTML('status').split(':');
	host = states[0];
	iface = states[1];
	id = states[2];

	ID="SPAN_"+host+id;
	description = document.getElementById(ID).getAttribute("description");
	protocol = document.getElementById(ID).getAttribute("protocol");
	dump_tool = document.getElementById(ID).getAttribute("dump_tool");

	if (protocol == "")
		protocol = "http";
	if (dump_tool == "")
		dump_tool = "/cgi-bin/vnstat.sh";
	if (description == "")
		description = host;

        showHTML("status", host+":"+iface+":"+id);
        showHTML("caption", caption);

        vnstat_xml = dump_tool+"?i="+iface+"&p="+page;
	/* document.domain is the domain name of the "server node", you'd better set 'host' as it */
	/* Note: document.domain is 'undefined' while using firefox to browse busybox httpd, ignore multi-hosts support for such case */
      //  if ((document.domain && host != document.domain) || protocol != "http") {
        //        vnstat_xml=vnstat_proxy+"?"+protocol+"://"+host+vnstat_xml;
       // }

	// if the bandwidth is "narrow", you can try to uncomment the following line
	showHTML("main_wrapper", "<font color='blue'>Loading...</font>");

	divID="main_wrapper"; xmlFile=vnstat_xml; xslFile=vnstat_xsl;
        showXML();
}

function showMenu(host, iface, id)
{
	if (iface == "")
		iface = "eth0";

        showHTML("status", host+":"+iface+":"+id);

	showHTML("caption", "Click to monitor network traffic.");

	showHTML("main_wrapper", "<p align='center'>Traffic data will be loaded here...</p>");

	hideotherSubmenu(host, id);

	showSubmenu(host, id);
}

function hideotherSubmenu(host, id)
{
	me = host + id;
	spans = document.getElementsByTagName('span');
	for (i=0; i < spans.length; i ++) {
		spanID = spans[i].id;
		spanIDs = spanID.split('_');	/* SPAN_hostid */
		prefix = spanIDs[0];
		divID = spanIDs[1];
		if (prefix == 'SPAN' && divID != me && getHTML(spanID) == '-') {
			clearTimeout ( alertTimerId );
			showHTML(spanID, '+');
			showHTML(divID, ''); 
		}
	}
}

function showSubmenu(host, id)
{
	divID = host+id;
	spanID="SPAN_"+divID;

	if(getHTML(spanID) == '-') {
		clearTimeout ( alertTimerId );
		showHTML(spanID, '+');
		showHTML(divID, ''); 
	} else {
		showHTML(spanID,'-');
		xmlFile="menu.xml"; xslFile="menu.xsl";
		showXML();
	}
}

function getHTML(ID)
{
	return document.getElementById(ID).innerHTML;
}

function showHTML(ID, content)
{
	document.getElementById(ID).innerHTML = content;
	return;
}

function showXML()
{
	clearTimeout ( alertTimerId );

	xmlHttp=GetXmlHttpObject();
	if (xmlHttp == null) return;

	xmlHttp.onreadystatechange = stateChanged;
	xmlHttp.open("GET", xmlFile, true);
	xmlHttp.send(null);
	if(xmlFile.lastIndexOf("second") > 0) {
		alertTimerId=setTimeout("showXML()", speed);
	}
}

function stateChanged()
{
	if (xmlHttp.readyState == 4)
	{
		if (xmlHttp.status == 200 ) {
	    	// Only support Firefox, Opera 8.0+, Safari
	    	var xmlDoc=xmlHttp.responseXML;
		var content;

		if (document.implementation && document.implementation.createDocument) {
			// Chromium, Firefox, Mozilla, Opera, etc.
			//load xsl file
			//var xslDoc =  document.implementation.createDocument("", "", null);
			//xslDoc.async = false;
			//xslDoc.load(xslFile);
			var xslHttp = new XMLHttpRequest();
			xslHttp.open("GET", xslFile, false);
			xslHttp.send();
			var xslDoc = xslHttp.responseXML.documentElement;

			//build the relationship between xml file and xsl file
			var xsl = new XSLTProcessor();
			xsl.importStylesheet(xslDoc);

			var result = xsl.transformToDocument(xmlDoc);
			var xmls = new XMLSerializer();

			// serialize to string
			content = xmls.serializeToString(result);

			// filter the xml header for mozilla/5.0-based firefox 3.0
			if (content.indexOf("<?xml") > -1) {
				var index = content.indexOf(">") + 2;
				var subcontent = content.substr(index);
				content = subcontent;
			}
		} else if(typeof window.ActiveXObject != 'undefined') {
		        //load xsl file
        		xslDoc = new ActiveXObject('Microsoft.XMLDOM');
		        xslDoc.async = false;
	        	xslDoc.load(xslFile);

			content = xmlDoc.documentElement.transformNode(xslDoc);
	    	}
		// append the result
		showHTML(divID, content);
	    } else showHTML(divID, 'Error with XMLHttpRequest!');
	}
}

function GetXmlHttpObject()
{
	var xmlHttp=null;
	try
	{
	  	// Firefox, Opera 8.0+, Safari
		xmlHttp=new XMLHttpRequest();
	}
	catch (e)
	{
		// Internet Explorer: vnStatSVG not support IE currently, Hope one day, IE no long imperious and support AJAX directly!!
		try
		{
			xmlHttp=new ActiveXObject("Msxml2.XMLHTTP");
		}
		catch (e)
		{
			xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");
		}
	}
	return xmlHttp;
}
