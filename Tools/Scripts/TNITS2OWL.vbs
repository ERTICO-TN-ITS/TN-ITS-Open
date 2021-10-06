option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: TNITS2OWL
' Author: Knut Jetlund
' Purpose: Export the TN-ITS UML Model to OWL
' Date: 20210927
'

'-----------------------------------------------------------------------------------------------------------------------------------
'Constants
'const owlURI = "http://spec.tn-its.eu/owl/tnits-owl"
const owlPath = "C:\DATA\GitHub\ERTICO-TN-ITS\TN-ITS-Open\OWL\core"
'const filename = "tnits-owl"
'const strPrefix = "tnits"

'-----------------------------------------------------------------------------------------------------------------------------------
'Global parameters
dim owlURI, strPrefix, filename
dim objFSO, objOTLFile
dim thePackage as EA.Package
dim pck as EA.Package
dim el as EA.Element
dim relEl as EA.Element
dim eTag as EA.TaggedValue
dim con as EA.Connector
dim conEnd as EA.ConnectorEnd
dim rTag as EA.RoleTag
dim attr as EA.Attribute
dim aTag as EA.AttributeTag
dim lstOP, lstDP
dim definition, rangeName
dim strDjFeature, strDjCode, strDjEnum, strDjDT
dim coreClass
dim lstClasses, lstUniquePropertyNames, lstDuplicatePropertyNames, lstGlobalPropertyNames, lstCreatedProperties
dim propertyName, propertyDef
dim isGlobal, hasGlobalRange
dim i
dim dt, range, lower, upper
dim oneOfEnum

'-----------------------------------------------------------------------------------------------------------------------------------


sub heading
	'Heading for the ontology - content should be configurable
	'---------------------------------------------------------------------------------------------------------------------------
	'Namespaces for the ontology
	'objOTLFile.WriteText "" & vbCrLf
	objOTLFile.WriteText "@prefix : <" & owlURI & "#> ." & vbCrLf
	objOTLFile.WriteText "@prefix dc: <http://purl.org/dc/elements/1.1/> ." & vbCrLf
	'ISO 19148 from the INTERLINK Ontologies
	objOTLFile.WriteText "@prefix lr: <http://www.roadotl.eu/iso19148/def/> ." & vbCrLf
	'OGC Simple feature
	objOTLFile.WriteText "@prefix sf: <http://www.opengis.net/ont/sf#> ." & vbCrLf
	'OGC GeoSPARQL
	objOTLFile.WriteText "@prefix gsp: <http://www.opengis.net/ont/geosparql#> ." & vbCrLf
	'W3C Core ontologies
	objOTLFile.WriteText "@prefix owl: <http://www.w3.org/2002/07/owl#> ." & vbCrLf
	objOTLFile.WriteText "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ." & vbCrLf
	objOTLFile.WriteText "@prefix xml: <http://www.w3.org/XML/1998/namespace> ." & vbCrLf
	objOTLFile.WriteText "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ." & vbCrLf
	objOTLFile.WriteText "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ." & vbCrLf
	objOTLFile.WriteText "@prefix skos: <http://www.w3.org/2004/02/skos/core#> ." & vbCrLf
	objOTLFile.WriteText "@prefix dcterms: <http://purl.org/dc/terms/> ." & vbCrLf
	
	objOTLFile.WriteText vbCrLf
	objOTLFile.WriteText "<" & owlURI & "> a owl:Ontology ;" & vbCrLf
	
	' -------------------------------------------------------------------------
	'Imports
	'SKOS
	objOTLFile.WriteText "	owl:imports <http://www.w3.org/2004/02/skos/core> ;" & vbCrLf
	'OGC GeoSparql
	objOTLFile.WriteText "	owl:imports <http://schemas.opengis.net/geosparql/1.0/geosparql_vocab_all.rdf> ;" & vbCrLf
	'ISO 19148 from the INTERLINK Ontologies
	objOTLFile.WriteText "	owl:imports <https://www.roadotl.eu/static/eurotl-ontologies/iso19148_doc/ontology.ttl> ;" & vbCrLf
	'ISO 19115 Metadata
	objOTLFile.WriteText "	owl:imports <http://def.isotc211.org/iso19115/-1/2014/MetadataInformation.rdf> ;" & vbCrLf
	'TN-ITS Codes
	objOTLFile.WriteText "	owl:imports <http://spec.tn-its.eu/owl/tnits-owl/codes> ;" & vbCrLf
	
	
	' --------------------------------------------------------------------
	
	'Ontology metadata 
	objOTLFile.WriteText "	dc:creator ""TN-ITS"" ;" & vbCrLf
	objOTLFile.WriteText "	dc:date """ & left(Now,10) & """ ;" & vbCrLf
	objOTLFile.WriteText "	dc:description ""Ontology for the TN-ITS model for exchange of changes in road attributes""@en ;" & vbCrLf
	objOTLFile.WriteText "	dcterms:title ""TN-ITS""@en ;" & vbCrLf
	objOTLFile.WriteText "	dcterms:abstract ""Ontology for exchange of changes in road attributes"" ." & vbCrLf
	objOTLFile.WriteText vbCrLf
end sub

sub coreClasses
'Create core classes for the ontology
	'---------------------------------------------------------------------------------------------------
	'Root class
	objOTLFile.WriteText "### " & owlURI & "#" & coreClass & vbCrLf
	objOTLFile.WriteText ":" & coreClass &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         owl:disjointUnionOf ( :" & strPrefix & "Feature :" & strPrefix & "CodeList :" & strPrefix & "Enumeration :" & strPrefix & "DataType" & " ) ;" & vbCrLf 		
	objOTLFile.WriteText "         rdfs:label """ & thePackage.Name & " Root""@en ." & vbCrLf 	
	'TN-ITS Feature as subtype of ISO 19109 AnyFeature and GeoSPARQL Feature
	objOTLFile.WriteText "### " & owlURI & "#Feature" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "Feature" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:subClassOf <http://def.isotc211.org/iso19109/2015/GeneralFeatureModel#AnyFeature> ," & vbCrLf
    objOTLFile.WriteText  "                          :" & coreclass & " ," & vbCrLf
    objOTLFile.WriteText  "                       gsp:Feature ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label ""TN-ITS Feature""@en ." & vbCrLf 	
	strDjFeature = ":" & strPrefix & "Feature owl:disjointUnionOf ( "
	'Core class for all code values
	objOTLFile.WriteText "### " & owlURI & "#CodeList" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "CodeList" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:subClassOf :" & coreClass & ", skos:Concept ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label ""TN-ITS Code value""@en ." & vbCrLf 	
	strDjCode = ":" & strPrefix & "CodeList owl:disjointUnionOf ( "
	'Core class for all enumerations
	objOTLFile.WriteText "### " & owlURI & "#Enumeration" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "Enumeration" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:subClassOf :" & coreClass & ", skos:Concept ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label ""TN-ITS Enumeration value""@en ." & vbCrLf 					
	strDjEnum = ":" & strPrefix & "Enumeration owl:disjointUnionOf ( "
	'Core class for all datatypes
	objOTLFile.WriteText "### " & owlURI & "#DataType" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "DataType" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:subClassOf :" & coreClass & " ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label ""TN-ITS Data type""@en ." & vbCrLf 	
	strDjDT = ":" & strPrefix & "DataType owl:disjointUnionOf ( "
	'------------------------------------------------------------------------------------------
end sub

sub addPropertyLists
'Add attributes and associaton ends to internal property lists
	if isGlobal then
		'Add attribute to list of global properties, with information concerning global range
		Repository.WriteOutput "Script", Now & " Global property. Adding <" & propertyName & "> to the list of global property names", 0 
		if not lstGlobalPropertyNames.Contains(propertyName) then lstGlobalPropertyNames.Add propertyName, hasGlobalRange
	elseif not lstUniquePropertyNames.Contains(propertyName) then 
		'Not identified yet - add to list of unique names
		Repository.WriteOutput "Script", Now & " New property name. Adding <" & propertyName & "> to the list of unique property names", 0 
		lstUniquePropertyNames.Add propertyName, propertyName
	else	
		'Not global, but already identified - add to list of duplicate names
		Repository.WriteOutput "Script", Now & " Duplicate property name. Adding <" & propertyName & "> to the list of duplicate property names", 0 
		if not lstDuplicatePropertyNames.Contains(propertyName) then lstDuplicatePropertyNames.Add propertyName, propertyName
	end if
end sub

sub recClassList(p)
'Recusive traverse through package and create list of class and property names
	set pck = p
	Repository.WriteOutput "Script", Now & " Traversing package " & pck.Name, 0 
	'--------------------------------------------------------------------------------------------------
	'List of classes, for avoiding duplicate names on classes and properties
	for each el in pck.Elements
		if el.Type = "Class" or el.Type="Enumeration" or el.Type = "DataType" then 
			Repository.WriteOutput "Script", Now & " Adding <" & el.Name & "> to the list of classes", 0 
			lstClasses.Add UCase(el.name),el.ElementGUID
			
			if UCase(el.Stereotype) = "FEATURETYPE" or UCase(el.Stereotype) = "DATATYPE" then 
				'Lists of properties, for avoiding duplicate property names
				
				for each attr in el.Attributes 
					'Identify global properties from tagged values
					isGlobal = false
					hasGlobalRange = false		
					for each aTag in attr.TaggedValues
						if aTag.Name = "isGlobal" and aTag.Value = "true" then isglobal = true
						if aTag.Name = "hasGlobalRange" and aTag.Value = "true" then hasGlobalRange = true					
					next
					
					propertyName = attr.Name
					addPropertyLists
				next
								
				for each con in el.Connectors
					getConEnd
					if (con.type = "Aggregation" or con.Type = "Association") and conEnd.Navigable <> "Non-Navigable" and conEnd.Role <> "" then	
						isGlobal = false
						hasGlobalRange = false		
						for each rTag in conEnd.TaggedValues
							if rTag.Tag = "isGlobal" and rTag.Value = "true" then isglobal = true
							if rTag.Tag = "hasGlobalRange" and rTag.Value = "true" then hasGlobalRange = true					
						next
						propertyName = conEnd.Role
						addPropertyLists
					end if
				next
			end if
		end if	
	Next
	
	dim subP as EA.Package
	for each subP in pck.packages
	    recClassList subP 
	next
end sub 


sub createProperty
'--------------------------------------------------------------------------------
'Create property and set restrictions
	'Set unique property name and check whether range shall be set 
	if lstGlobalPropertyNames.Contains(propertyName) then
		'Check for global range - global properties may have different ranges for different classes
		i = lstGlobalPropertyNames.IndexofKey(propertyName)
		hasGlobalRange = lstGlobalPropertyNames.GetByIndex(i)
	elseif not lstGlobalPropertyNames.Contains(propertyName) then
		'Make sure the property name is unique
		if lstClasses.Contains(UCASE(propertyName)) or lstDuplicatePropertyNames.Contains(propertyName) then 
			'Define unique property name by adding prefix Class name + "." 
			propertyName = el.Name & "." & propertyName
		else
			hasGlobalRange = true 'All UML properties have global range by default
		end if	
	end if	
			
	'-----------------------------------------------------------------------------------------
	'Create property if not created
	if not lstCreatedProperties.Contains(propertyName) then
		objOTLFile.WriteText vbCrLf
		objOTLFile.WriteText "### " & owlURI & "#" & propertyName & vbCrLf
		if dt = "d" then
			Repository.WriteOutput "Script", Now & " Datatype property: " & propertyName & " , cardinality: " & lower & ".." & upper & " (Range = " & range & ")", 0 
			objOTLFile.WriteText ":" & propertyName & " rdf:type owl:DatatypeProperty ;" & vbCrLf
		else
			Repository.WriteOutput "Script", Now & " Object property: " & propertyName & " , cardinality: " & lower & ".." & upper & " (Range = " & range & ")", 0 
			objOTLFile.WriteText ":" & propertyName & " rdf:type owl:ObjectProperty ;" & vbCrLf
		end if
		'---------------------------
		'Set defintion if not empty
		if not propertyDef = "" then 
			propertyDef = replace(propertyDef, """","\""")
			propertyDef = replace(propertyDef, vbCrLf," ")	
			objOTLFile.WriteText "         skos:definition """ & propertyDef & """@en ;" & vbCrLf
		end if	
		'---------------------------
		'Set domain if not global property
		if not lstGlobalPropertyNames.Contains(propertyName) then objOTLFile.WriteText "         rdfs:domain :" & el.Name & ";" & vbCrLf
		'---------------------------
		'Set range if hasGlobalRange
		if hasGlobalRange then objOTLFile.WriteText "         rdfs:range " & range & ";" & vbCrLf
		'Set functional property if cardinality = 1 and not global. 
		if (not lstGlobalPropertyNames.Contains(propertyName)) and lower = "1" and upper = "1" then objOTLFile.WriteText "         rdf:type owl:FunctionalProperty;" & vbCrLf

		'Close property statement with "."
		objOTLFile.WriteText "         rdfs:label """ & propertyName & """@en ." & vbCrLf 	
		'Add to list of created properties (only for global properties?)
		lstCreatedProperties.Add propertyName, ""
	end if
	
	'--------------------------------------------------------------------------------------------
	'Set cardinality restrictions for the property on this specific class
	if not (lower = "0" and upper = "*") then 'No cardinality requirements on 0..*
		objOTLFile.WriteText ":" & el.Name & " rdfs:subClassOf [ rdf:type owl:Restriction ;" & vbCrLf
		objOTLFile.WriteText "         owl:onProperty :" & propertyName & ";" & vbCrLf 	
		if dt = "d" then
			objOTLFile.WriteText "         owl:onDataRange " & range & ";" & vbCrLf 		
		else
			objOTLFile.WriteText "         owl:onClass " & range & ";" & vbCrLf 		
		end if
		if lower = upper then 
			objOTLFile.WriteText "       owl:qualifiedCardinality """ & lower & """^^xsd:nonNegativeInteger ;" & vbCrLf 'Exact cardinality
		else
			if lower <> "0" then objOTLFile.WriteText "       owl:minQualifiedCardinality """ & lower & """^^xsd:nonNegativeInteger ;" & vbCrLf 'Lower <> 0 --> Mandatory, minimum cardinality		
			if upper <> "*" then objOTLFile.WriteText "       owl:maxQualifiedCardinality """ & upper & """^^xsd:nonNegativeInteger ;" & vbCrLf 'Upper <> * --> Restricted maximum cardinality	
		end if
		objOTLFile.WriteText "         ] ." & vbCrLf
	end if	
	'All values from
	objOTLFile.WriteText ":" & el.Name & " rdfs:subClassOf [ rdf:type owl:Restriction ;" & vbCrLf
	objOTLFile.WriteText "         owl:onProperty :" & propertyName & ";" & vbCrLf 	
	objOTLFile.WriteText "         owl:allValuesFrom " & range & ";" & vbCrLf 	
	objOTLFile.WriteText "         ] ." & vbCrLf
	objOTLFile.WriteText vbCrLf
end sub

sub getConEnd
'Get the correct connector end and associated elements
	if con.ClientID = el.ElementID then
		set relEl = Repository.GetElementByID(con.SupplierID)
		set conEnd = con.SupplierEnd
	else
		set relEl = Repository.GetElementByID(con.ClientID)
		set conEnd = con.ClientEnd
	end if 		
end sub

sub recPackageTraverse(p)
'----------------------------------------------------------------------------------------------------
'Recursive traverse through package structure
	set pck = p
	Repository.WriteOutput "Script", Now & " Traversing package " & pck.Name, 0 
	objOTLFile.WriteText vbCrLf
	'------------------------------------------------------------------------------------------------------
	for each el in pck.Elements
		'Initiate disjointUnionOf string 
		dim strDjCls
		strDjCls = 	":" & el.Name & " owl:disjointUnionOf ( "
		'------------------------------------------------------------------------------------------------------
		'Classes -- as OWL Classes
		if el.Type = "Class" or el.Type="Enumeration" or el.Type = "DataType" then 
			'Create class
			objOTLFile.WriteText vbCrLf
			Repository.WriteOutput "Script", Now & " Element: " & el.Stereotype & " " & el.Name, 0 
			objOTLFile.WriteText "### " & owlURI & ":" & el.Name & vbCrLf
			objOTLFile.WriteText ":" & el.Name & " a owl:Class ;" & vbCrLf
			'------------------------------------------------------------------------------------------------------
			'Check whether the class is a subtype. If so, do not subtype directly under core classes
			dim subcls
			subcls = false
			For each con in el.Connectors
				if con.Type = "Generalization" and con.ClientID = el.ElementID then	subcls = true
			next	
			
			'Place classes under core classes 
			if not subcls then
				if UCase(el.Stereotype) = "FEATURETYPE" then
					objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "Feature ;" & vbCrLf	
					strDjFeature = strDjFeature & ":" & el.Name & " "
				elseif UCase(el.Stereotype) = "CODELIST" then
					objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "CodeList ;" & vbCrLf	
					strDjCode = strDjCode & ":" & el.Name & " "
				elseif UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration" then			
					objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "Enumeration ;" & vbCrLf	
					strDjEnum = strDjEnum & ":" & el.Name & " "
				elseif UCase(el.Stereotype) = "DATATYPE" then
					objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "DataType ;" & vbCrLf	
					strDjDT = strDjDT & ":" & el.Name & " "
				end if
			end if	
			'------------------------------------------------------------------------------------------------------
			'Definition
			if not el.Notes = "" then 
				definition = replace(el.Notes, """","\""")
				definition = replace(definition, vbCrLf," ")	
				objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
			end if	
			objOTLFile.WriteText "       rdfs:label """ & el.Name & """@en ." & vbCrLf 

			'---------------------------------------------------------------------------------------------------------
			'Create concept schemes for enumerations (code list schemes are in the codes ontology)
			if UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration"  then		'or UCase(el.Stereotype) = "CODELIST"
				objOTLFile.WriteText vbCrLf
				objOTLFile.WriteText "### " & owlURI & ":" & el.Name & "Code" & vbCrLf
				objOTLFile.WriteText ":" & el.Name & "Code a skos:ConceptScheme ;" & vbCrLf		
				if not el.Notes = "" then 
					definition = replace(el.Notes, """","\""")
					definition = replace(definition, vbCrLf," ")	
					objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
				end if	
				objOTLFile.WriteText "       dc:isFormatOf :" & el.Name & " ." & vbCrLf
			end if	
				
			'------------------------------------------------------------------------------------------------------
			'Relations - generalizations and associations
			For each con in el.Connectors
				getConEnd
				
				'------------------------------------------------------------------------------------------------------
				'Generalization - subclass axiom
				if con.Type = "Generalization" and con.ClientID = el.ElementID then
					Repository.WriteOutput "Script", Now & " Subclass of " & relEl.Name, 0 
					objOTLFile.WriteText ":" & el.Name & " rdfs:subClassOf :" & relEl.Name & " ." & vbCrLf	
				'Generalization - disjointUnionOf for the superclass
				elseif con.Type = "Generalization" and con.SupplierID = el.ElementID then
					Repository.WriteOutput "Script", Now & " Superclass for " & relEl.Name, 0 
					strDjCls = strDjCls & ":" & relEl.Name & " "
				'------------------------------------------------------------------------------------------------------
				'Associations - object properties
				elseif (con.type = "Aggregation" or con.Type = "Association") and conEnd.Navigable <> "Non-Navigable" and conEnd.Role <> "" then	
					dt = "o"
					propertyName = conEnd.Role
					propertyDef = conEnd.RoleNote
					dim crdArr
					crdArr = split(conEnd.Cardinality,"..")
					lower = crdArr(0)
					if Ubound(crdArr) = 0 then upper = lower else upper = crdArr(1)		
					if not relEl is nothing then 
						range = ":" & relEl.Name
						for each rTag in conEnd.TaggedValues
							if rTag.Tag = "rangeVocabulary" then range = "<" & rTag.Value & "#" & relEl.Name & ">"
							if rTag.Tag = "rangeClass" then range = "<" & rTag.Value & ">" 
						next
						createProperty
					else
						Repository.WriteOutput "Error", Now & " Unknown type for property: " & propertyName & " , cardinality: " & lower & ".." & upper, 0 
					end if	
				end if
			next
			'-----------------------------------------------------------------------------------------------------------
			'Attributes as properties for feature types and datatypes
			if UCase(el.Stereotype) = "FEATURETYPE" or UCase(el.Stereotype) = "DATATYPE" then
				For each attr in el.Attributes
					'------------------------------------------------------------------------------
					'Find type of property (data or object) and range
					Select Case attr.Type
						Case "CharacterString","Integer","Real","Date","DateTime","Boolean":
							'Datatype property, mapping to XSD Datatypes
							dt = "d"
							Select Case attr.Type
								Case "CharacterString": 
									range = "xsd:string"
								Case "Integer":
									range = "xsd:integer"							
								Case "Real":
									range = "xsd:double"
								Case "Date":
									range = "xsd:date"
								Case "DateTime":
									range = "xsd:dateTime"
								Case "Boolean":
									range = "xsd:boolean"
							End Select					
					case else
						'Object Property (name and definition)
						dt = "o"
						if not attr.ClassifierID = 0 then 
							'Find related element
							set relEl = Repository.GetElementByID(attr.ClassifierID)
							range = ":" & relEl.Name
							'For external classes: Get URI from attribute tag rangeVocabulary or rangeClass
							for each aTag in attr.TaggedValues
								if aTag.Name = "rangeVocabulary" then range = "<" & aTag.Value & "#" & relEl.Name & ">"
								if aTag.Name = "rangeClass" then range = "<" & aTag.Value & ">" '& "#" & relEl.Name & ">"
							next	
						else
							dt = "-"
						end if	
					End Select	
					
					propertyName = attr.Name
					propertyDef = attr.Notes
					lower = attr.LowerBound
					upper = attr.UpperBound
					if not dt = "-" then 
						createProperty
					else
						Repository.WriteOutput "Error", Now & " Unknown type for property: " & propertyName & " , cardinality: " & lower & ".." & upper, 0 
					end if
				next
			end if 
			
			'----------------------------------------------------------------------------------------------------------
			'Codelist or enumeration values - instances of classes
			if 	UCase(el.Stereotype) = "CODELIST" or UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration" then
				'Initiate oneOf statement
				oneOfEnum = ":" & el.Name & " owl:oneOf ( " 
				For each attr in el.Attributes
					'Include value in oneOf-statement 
					oneOfEnum = oneOfEnum & ":" & el.Name & "." & attr.Name & " "
					objOTLFile.WriteText vbCrLf
					objOTLFile.WriteText "### " & owlURI & ":" & el.Name & "." & attr.Name & vbCrLf
					'objOTLFile.WriteText ":" & el.Name & "." & attr.Name & " a :" & el.Name & " ;" & vbCrLf
					objOTLFile.WriteText ":" & el.Name & "." & attr.Name & " a :" & el.Name & ",skos:Concept ;" & vbCrLf
					objOTLFile.WriteText "         skos:inScheme :" &  el.Name & "Code ;" & vbCrLf					
					if not attr.Notes = "" then 
						definition = replace(attr.Notes, """","\""")
						definition = replace(definition, vbCrLf," ")	
						objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
					end if	
					objOTLFile.WriteText "         rdfs:label """ & attr.Name & """@no ." & vbCrLf					
				next	
				'Close and write oneOf statement 
				oneOfEnum = oneOfEnum & " ) ; ." 
				if 	(UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration") and InStr(oneOfEnum,"owl:oneOf (  )") = 0 then objOTLFile.WriteText oneOfEnum & vbCrLf			
			end if
		end if
		'Close and write non-empty disjoint union strings for classes
		strDjCls = strDjCls & " ) ; ."
		if 	InStr(strDjCls,"owl:disjointUnionOf (  )") = 0 then objOTLFile.WriteText strDjCls & vbCrLf	
	next
	

	dim subP as EA.Package
	for each subP in pck.packages
	    recPackageTraverse subP
	next
	
end sub

sub main
	'Script tabs
	Repository.EnsureOutputVisible "Script"
	Repository.ClearOutput "Script"
	Repository.CreateOutputTab "Error"
	Repository.ClearOutput "Error"
	Repository.CreateOutputTab "OWL"
	Repository.ClearOutput "OWL"

	set thePackage = Repository.GetTreeSelectedPackage
		
	if thePackage is nothing then
		Repository.WriteOutput "Error", Now & " No selected package", 0 
		exit sub
	end if
	
	'Find package tags for URI and namespace abbreviation
	owlURI = ""
	strPrefix = ""
	Repository.WriteOutput "Script", Now & " Main package: " & thePackage.Name, 0 
	for each eTag in thePackage.Element.TaggedValues
		if eTag.Name = "owlNamespace" then owlURI = eTag.Value
		If eTag.Name = "xmlns" then strPrefix = eTag.Value
	next
	If owlURI = "" or strPrefix = "" then 
		Repository.WriteOutput "Error", Now & " Missing namespace or namespace abbreviation", 0 
		exit sub
	end if

	'---------------------------------------------------------------------
	'Create text stream
	Set objFSO=CreateObject("Scripting.FileSystemObject")
	Set objOTLFile = CreateObject("ADODB.Stream")
	objOTLFile.CharSet = "utf-8"
	objOTLFile.Open
	
	'dim filetime
	'filetime = replace(Now, ".","")
	'filetime = replace(filetime, ":","")
	'filetime = replace(filetime, " ","_")
	
	'---------------------------------------------------------------------
	'Create ontology with prefixes, imports and core classes
	Repository.WriteOutput "Script", Now & " Creating ontology with prefixes, imports and core classes...", 0 
	coreClass = strPrefix 
	heading
	coreClasses	
	
	'---------------------------------------------------------------------
	'Create internal lists of classes and properties
	Repository.WriteOutput "Script", Now & " ----------------------------------------------",0
	Repository.WriteOutput "Script", Now & " Creating internal lists of classes and properties...", 0 
	Set lstOP = CreateObject("System.Collections.SortedList")
	Set lstDP = CreateObject("System.Collections.SortedList")
	Set lstClasses = CreateObject("System.Collections.SortedList")
	Set lstUniquePropertyNames = CreateObject("System.Collections.SortedList")
	Set lstDuplicatePropertyNames = CreateObject("System.Collections.SortedList")
	Set lstGlobalPropertyNames = CreateObject("System.Collections.SortedList")
	Set lstCreatedProperties = CreateObject("System.Collections.SortedList")
	'Loop through packages, classes and properties
	recClassList thePackage
	
	'Documentation of global and dupliacte properties
	Repository.WriteOutput "Script", Now & " ----------------------------------------------",0
	Repository.WriteOutput "Script", Now & " Global properties:",0
	for i = 0 To lstGlobalPropertyNames.Count - 1
		Repository.WriteOutput "Script", Now & " " & lstGlobalPropertyNames.GetKey(i) & " (hasGlobalRange = " & lstGlobalPropertyNames.GetByIndex(i) & ")",0
	next
	Repository.WriteOutput "Script", Now & " ----------------------------------------------",0
	Repository.WriteOutput "Script", Now & " Duplicate property names:",0
	for i = 0 To lstDuplicatePropertyNames.Count - 1
		Repository.WriteOutput "Script", Now & " " & lstDuplicatePropertyNames.GetKey(i) ,0
	next
		
	'---------------------------------------------------------------------
	'Loop through packages and create classes and properties
	Repository.WriteOutput "Script", Now & " ----------------------------------------------",0
	recPackageTraverse thePackage
		
	'---------------------------------------------------------------------
	'Close and write disjoint union strings 
	strDjFeature = strDjFeature & "    ) ; ."
	objOTLFile.WriteText strDjFeature & vbCrLf	
	'No disjoint union for code lists, as a value may be relevant in several code lists
	'strDjCode = strDjCode & "    ) ; ."
	'objOTLFile.WriteText strDjCode & vbCrLf	
	strDjEnum = strDjEnum & "    ) ; ."
	objOTLFile.WriteText strDjEnum & vbCrLf	
	strDjDT = strDjDT & "    ) ; ."
	objOTLFile.WriteText strDjDT & vbCrLf	
	
	'---------------------------------------------------------------------
	'Write to file
	dim fn
	'filename = owlPath & "\" & filetime & "_" & filename & ".ttl"
	fn = owlPath & "\" & strPrefix & "-owl.ttl"
	If objFSO.FileExists(fn) then objFSO.DeleteFile fn, true
	Repository.WriteOutput "Script", Now & " Writing to file " & fn, 0 
	objOTLFile.SaveToFile fn, 2
	objOTLFile.Close
	
	Repository.WriteOutput "Script", Now & " Done. Check the Error tab", 0 
	Repository.EnsureOutputVisible "Script"


end sub

main