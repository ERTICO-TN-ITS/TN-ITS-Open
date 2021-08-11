option explicit

!INC Local Scripts.EAConstants-VBScript

' Script Name: TNITS2OWL
' Author: Knut Jetlund
' Purpose: Export the TN-ITS UML Model to OWL
' Date: 20210615
'
!INC TN-ITS.Parameters

dim objFSO, objOTLFile
dim thePackage as EA.Package
dim pck as EA.Package
dim el as EA.Element
dim relEl as EA.Element
dim con as EA.Connector
dim conEnd as EA.ConnectorEnd
dim rTag as EA.RoleTag
dim attr as EA.Attribute
dim aTag as EA.AttributeTag
dim lstOP, lstDP
dim definition, rangeName


sub heading
	'Create heading for the ontology
	'objOTLFile.WriteText "" & vbCrLf
	objOTLFile.WriteText "@prefix : <" & owlURI & "#> ." & vbCrLf
	objOTLFile.WriteText "@prefix dc: <http://purl.org/dc/elements/1.1/> ." & vbCrLf
	objOTLFile.WriteText "@prefix lr: <http://www.roadotl.eu/iso19148/def/> ." & vbCrLf
	objOTLFile.WriteText "@prefix sf: <http://www.opengis.net/ont/sf#> ." & vbCrLf
	objOTLFile.WriteText "@prefix gsp: <http://www.opengis.net/ont/geosparql#> ." & vbCrLf
	objOTLFile.WriteText "@prefix owl: <http://www.w3.org/2002/07/owl#> ." & vbCrLf
	objOTLFile.WriteText "@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> ." & vbCrLf
	objOTLFile.WriteText "@prefix xml: <http://www.w3.org/XML/1998/namespace> ." & vbCrLf
	objOTLFile.WriteText "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> ." & vbCrLf
	objOTLFile.WriteText "@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> ." & vbCrLf
	objOTLFile.WriteText "@prefix skos: <http://www.w3.org/2004/02/skos/core#> ." & vbCrLf
	objOTLFile.WriteText "@prefix dcterms: <http://purl.org/dc/terms/> ." & vbCrLf
	
	objOTLFile.WriteText vbCrLf
	objOTLFile.WriteText "<" & owlURI & "> a owl:Ontology ;" & vbCrLf
	objOTLFile.WriteText "	owl:imports <http://www.w3.org/2004/02/skos/core> ;" & vbCrLf
	
	' -------------------------------------------------------------------------
	'Specific imports - should be configurable
	objOTLFile.WriteText "	owl:imports <http://schemas.opengis.net/geosparql/1.0/geosparql_vocab_all.rdf> ;" & vbCrLf
	objOTLFile.WriteText "	owl:imports <https://www.roadotl.eu/static/eurotl-ontologies/iso19148_doc/ontology.ttl> ;" & vbCrLf
	objOTLFile.WriteText "	owl:imports <http://def.isotc211.org/iso19115/-1/2014/MetadataInformation.rdf> ;" & vbCrLf
	' --------------------------------------------------------------------
	
	'objOTLFile.WriteText "	owl:versionInfo ""2.23"" ;" & vbCrLf
	objOTLFile.WriteText "	dc:creator ""TN-ITS"" ;" & vbCrLf
	objOTLFile.WriteText "	dc:date """ & left(Now,10) & """ ;" & vbCrLf
	objOTLFile.WriteText "	dc:description ""Ontology for the TN-ITS model for exchange of changes in road attributes""@en ;" & vbCrLf
	objOTLFile.WriteText "	dcterms:title ""TN-ITS""@en ;" & vbCrLf
	objOTLFile.WriteText "	dcterms:abstract ""Ontology for exchange of changes in road attributes"" ." & vbCrLf
	objOTLFile.WriteText vbCrLf
end sub

sub coreClasses
	'Create core classes for the ontology
	objOTLFile.WriteText "### " & owlURI & "#FeatureType" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "FeatureType" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "       rdfs:subClassOf <http://def.isotc211.org/iso19109/2015/GeneralFeatureModel#AnyFeature> ," & vbCrLf
    objOTLFile.WriteText  "                       gsp:Feature ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label ""Feature type""@en ." & vbCrLf 				
	objOTLFile.WriteText "### " & owlURI & "#CodeList" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "CodeList" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label ""Code list""@en ." & vbCrLf 					
	objOTLFile.WriteText "### " & owlURI & "#Enumeration" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "Enumeration" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label ""Enumeration""@en ." & vbCrLf 					
	objOTLFile.WriteText "### " & owlURI & "#DataType" & vbCrLf
	objOTLFile.WriteText ":" & strPrefix & "DataType" &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label ""Data type""@en ." & vbCrLf 	
	objOTLFile.WriteText "### " & owlURI & "#" & coreClass & vbCrLf
	objOTLFile.WriteText ":" & coreClass &  " a owl:Class ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label """ & thePackage.Name & """@en ." & vbCrLf 	
	objOTLFile.WriteText "### " & owlURI & "#OP" & coreClass & vbCrLf
	objOTLFile.WriteText ":OP" & coreClass &  " a owl:ObjectProperty ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label """ & thePackage.Name & " Object Properties""@en ." & vbCrLf 	
	objOTLFile.WriteText "### " & owlURI & "#DP" & coreClass & vbCrLf
	objOTLFile.WriteText ":DP" & coreClass &  " a owl:DatatypeProperty ;" & vbCrLf
	objOTLFile.WriteText "         rdfs:label """ & thePackage.Name & " Datatype Properties""@en ." & vbCrLf 	
	
end sub

sub recPackageTraverse(p,parent)
'Traverse through package structure
	set pck = p
	Repository.WriteOutput "Script", Now & " Traversing package " & pck.Name, 0 
	objOTLFile.WriteText vbCrLf
	dim clParent
	clParent = parent

	if pck.PackageGUID <> thePackage.PackageGUID then
		clParent = strPrefix & replace(pck.Name," ","")
		objOTLFile.WriteText ":" & clParent & " a owl:Class ;" & vbCrLf
		objOTLFile.WriteText "       rdfs:subClassOf :" & parent & " ;" & vbCrLf
		objOTLFile.WriteText "       rdfs:label """ & pck.Name & """@en ." & vbCrLf
	end if

	for each el in pck.Elements
		'Classes -- as OWL Classes
		if el.Type = "Class" or el.Type="Enumeration" then 
			Repository.WriteOutput "Script", Now & " Element: " & el.Stereotype & " " & el.Name, 0 
			objOTLFile.WriteText ":" & el.Name & " a owl:Class ;" & vbCrLf
			objOTLFile.WriteText "       rdfs:subClassOf :" & clParent & " ;" & vbCrLf
			if UCase(el.Stereotype) = "FEATURETYPE" then
				objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "FeatureType ;" & vbCrLf	
			elseif UCase(el.Stereotype) = "CODELIST" then
				objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "CodeList ;" & vbCrLf	
			elseif UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration" then			
				objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "Enumeration ;" & vbCrLf	
			elseif UCase(el.Stereotype) = "DATATYPE" then
				objOTLFile.WriteText "       rdfs:subClassOf :" & strPrefix & "DataType ;" & vbCrLf	
			end if

			if not el.Notes = "" then 
				definition = replace(el.Notes, """","\""")
				definition = replace(definition, vbCrLf," ")	
				objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
			end if	
			For each con in el.Connectors
				if con.ClientID = el.ElementID then
					set relEl = Repository.GetElementByID(con.SupplierID)
					set conEnd = con.SupplierEnd
				else
					set relEl = Repository.GetElementByID(con.ClientID)
					set conEnd = con.ClientEnd
				end if 		
				if con.Type = "Generalization" and con.ClientID = el.ElementID then
					'Subclass axiom
					objOTLFile.WriteText "       rdfs:subClassOf :" & relEl.Name & " ;" & vbCrLf					
				elseif (con.type = "Aggregation" or con.Type = "Association") and conEnd.Navigable <> "Non-Navigable" and conEnd.Role <> "" then	
					'Object property
					'Add to unique list of ObjectProperties. 
					if not lstOP.Contains(conEnd.Role) then lstOP.Add conEnd.Role, conEnd.RoleNote
					Repository.WriteOutput "Script", Now & " Role: " & conEnd.Role & " , cardinality: " & conEnd.Cardinality, 0 
					'Assign properties with multiplicities and ranges to classes (restrictions)
					objOTLFile.WriteText "       rdfs:subClassOf [ a owl:Restriction ;" & vbCrLf 
					'The property
					objOTLFile.WriteText "       owl:onProperty :" & conEnd.Role & " ;" & vbCrLf 
					'Multiplicity and Range
					rangeName = ":" & relEl.Name
					'for external classes: Get URI from role tag
					for each rTag in conEnd.TaggedValues
						if rTag.Tag = "rangeVocabulary" then rangeName = "<" & rTag.Value & "#" & relEl.Name & ">"
						if rTag.Tag = "rangeClass" then rangeName = "<" & rTag.Value & ">" '& "#" & relEl.Name & ">"
					next
										
					Select case conEnd.Cardinality
						case "1":
							objOTLFile.WriteText "       owl:qualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 
							objOTLFile.WriteText "       owl:onClass " & rangeName & " ] ;" & vbCrLf 
						case "0..1":
							objOTLFile.WriteText "       owl:maxQualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 
							objOTLFile.WriteText "       owl:onClass " & rangeName & " ] ;" & vbCrLf 
						case "1..*":
							objOTLFile.WriteText "       owl:minQualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 	
							objOTLFile.WriteText "       owl:onClass " & rangeName & " ] ;" & vbCrLf 
						case else
							objOTLFile.WriteText "       owl:allValuesFrom " & rangeName & " ] ;" & vbCrLf 							
					end select
				end if
			next
			
			if UCase(el.Stereotype) = "FEATURETYPE" or UCase(el.Stereotype) = "DATATYPE" then
			'Properties for feature types and datatypes
				For each attr in el.Attributes
					Repository.WriteOutput "Script", Now & " Attribute: " & attr.Name & " , cardinality: " & attr.LowerBound & ".." & attr.UpperBound & " (ClassifierID = " & attr.ClassifierID, 0 
					Select Case attr.Type
						Case "CharacterString","Integer","Real","Date","DateTime","Boolean":
							'Datatype Property (name and definition)
							'Add to unique list of DatatypeProperties. 
							if not lstDP.Contains(attr.Name) then lstDP.Add attr.Name, attr.Notes

							'Assign properties with multiplicities and ranges to classes (restrictions)
							objOTLFile.WriteText "       rdfs:subClassOf [ a owl:Restriction ;" & vbCrLf 
							'The property
							objOTLFile.WriteText "       owl:onProperty :" & attr.Name & " ;" & vbCrLf 
							'Convert range
							dim range
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
							'Multiplicity and Range
							if attr.LowerBound = "1" and attr.UpperBound = "1" then
								objOTLFile.WriteText "       owl:qualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 
								objOTLFile.WriteText "       owl:onDataRange " & range & " ] ;" & vbCrLf 
							elseif attr.LowerBound = "0" and attr.UpperBound = "1" then		
								objOTLFile.WriteText "       owl:maxQualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 
								objOTLFile.WriteText "       owl:onDataRange " & range & " ] ;" & vbCrLf 
							elseif attr.LowerBound = "1" and attr.UpperBound = "*" then		
								objOTLFile.WriteText "       owl:minQualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 	
								objOTLFile.WriteText "       owl:onDataRange " & range & " ] ;" & vbCrLf 
							else
								objOTLFile.WriteText "       owl:allValuesFrom " & range & " ] ;" & vbCrLf 							
							end if
					case else
						'Object Property (name and definition)
						'Add to unique list of ObjectProperties. 
						if not lstOP.Contains(attr.Name) then lstOP.Add attr.Name, attr.Notes
						
						if not attr.ClassifierID = 0 then 
							'Find related element
							set relEl = Repository.GetElementByID(attr.ClassifierID)
							rangeName = ":" & relEl.Name
							'for external classes: Get URI from attribute tag
							for each aTag in attr.TaggedValues
								if aTag.Name = "rangeVocabulary" then rangeName = "<" & aTag.Value & "#" & relEl.Name & ">"
								if aTag.Name = "rangeClass" then rangeName = "<" & aTag.Value & ">" '& "#" & relEl.Name & ">"
							next	
							'Assign properties with multiplicities and ranges to classes (restrictions)
							objOTLFile.WriteText "       rdfs:subClassOf [ a owl:Restriction ;" & vbCrLf 
							'The property
							objOTLFile.WriteText "       owl:onProperty :" & attr.Name & " ;" & vbCrLf 
							'Multiplicity and Range
							if attr.LowerBound = "1" and attr.UpperBound = "1" then
								objOTLFile.WriteText "       owl:qualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 
								objOTLFile.WriteText "       owl:onClass " & rangeName & " ] ;" & vbCrLf 
							elseif attr.LowerBound = "0" and attr.UpperBound = "1" then		
								objOTLFile.WriteText "       owl:maxQualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 
								objOTLFile.WriteText "       owl:onClass " & rangeName & " ] ;" & vbCrLf 
							elseif attr.LowerBound = "1" and attr.UpperBound = "*" then		
								objOTLFile.WriteText "       owl:minQualifiedCardinality ""1""^^xsd:nonNegativeInteger ;" & vbCrLf 	
								objOTLFile.WriteText "       owl:onClass " & rangeName & " ] ;" & vbCrLf 
							else
								objOTLFile.WriteText "       owl:allValuesFrom " & rangeName & " ] ;" & vbCrLf 							
							end if	
						else
							Repository.WriteOutput "Error", Now & " Attribute: " & attr.Name & " , cardinality: " & attr.LowerBound & ".." & attr.UpperBound & " (ClassifierID = " & attr.ClassifierID, 0 
						end if	

					End Select	
				next
			end if 
			objOTLFile.WriteText "       rdfs:label """ & el.Name & """@en ." & vbCrLf 
			
			
			if 	UCase(el.Stereotype) = "CODELIST" or UCase(el.Stereotype) = "ENUMERATION" or el.Type = "Enumeration" then	
			'Codelist or enumeration values - instances of classes
				For each attr in el.Attributes
					objOTLFile.WriteText vbCrLf
					objOTLFile.WriteText "### " & owlURI & "_" & el.Name & "_" & attr.Name & vbCrLf
					objOTLFile.WriteText ":" & el.Name & "_" & attr.Name & " rdf:type :" & el.Name & " ;" & vbCrLf
					if not attr.Notes = "" then 
						definition = replace(attr.Notes, """","\""")
						definition = replace(definition, vbCrLf," ")	
						objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
					end if	
					objOTLFile.WriteText "         rdfs:label """ & attr.Name & """@no ." & vbCrLf					
				next	
			end if
		end if
	next

	dim subP as EA.Package
	for each subP in pck.packages
	    recPackageTraverse subP,clParent 
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
	
	Repository.WriteOutput "Script", Now & " Main package: " & thePackage.Name, 0 

	'Create text stream
	Set objFSO=CreateObject("Scripting.FileSystemObject")
	Set objOTLFile = CreateObject("ADODB.Stream")
	objOTLFile.CharSet = "utf-8"
	objOTLFile.Open
	
	dim filetime
	filetime = replace(Now, ".","")
	filetime = replace(filetime, ":","")
	filetime = replace(filetime, " ","_")
	
	'Create lists for Object and Datatype Properties
	Set lstOP = CreateObject("System.Collections.SortedList")
	Set lstDP = CreateObject("System.Collections.SortedList")
	
	'*********************************
	'Create ontology and classes
	heading
	coreClasses	
	recPackageTraverse thePackage,coreClass

	'*********************************
	'Create unique properties
	dim i
	for i = 0 To lstOP.Count - 1
		Repository.WriteOutput "Script", Now & " Object property: " & lstOP.GetKey(i) ,0
		objOTLFile.WriteText vbCrLf
		objOTLFile.WriteText "### " & owlURI & "#" & lstOP.GetKey(i) & vbCrLf
		objOTLFile.WriteText ":" & lstOP.GetKey(i) & " rdf:type owl:ObjectProperty ;" & vbCrLf
		objOTLFile.WriteText "         rdfs:subPropertyOf :OP" & coreClass & " ;" & vbCrLf
		if not lstOP.GetByIndex(i) = "" then 
			definition = replace(lstOP.GetByIndex(i), """","\""")
			definition = replace(definition, vbCrLf," ")	
			objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
		end if	
		objOTLFile.WriteText "         rdfs:label """ & lstOP.GetKey(i) & """@en ." & vbCrLf 	
	next	
	for i = 0 To lstDP.Count - 1
		Repository.WriteOutput "Script", Now & " Datatype property: " & lstDP.GetKey(i) ,0
		objOTLFile.WriteText vbCrLf
		objOTLFile.WriteText "### " & owlURI & "#" & lstDP.GetKey(i) & vbCrLf
		objOTLFile.WriteText ":" & lstDP.GetKey(i) & " rdf:type owl:DatatypeProperty ;" & vbCrLf
		objOTLFile.WriteText "         rdfs:subPropertyOf :DP" & coreClass & " ;" & vbCrLf
		if not lstDP.GetByIndex(i) = "" then 
			definition = replace(lstDP.GetByIndex(i), """","\""")
			definition = replace(definition, vbCrLf," ")	
			objOTLFile.WriteText "         skos:definition """ & definition & """@en ;" & vbCrLf
		end if	
		objOTLFile.WriteText "         rdfs:label """ & lstDP.GetKey(i) & """@en ." & vbCrLf 	
	next
	
	dim fn
	'filename = owlPath & "\" & filetime & "_" & filename & ".ttl"
	fn = owlPath & "\" & filename & ".ttl"
	If objFSO.FileExists(fn) then objFSO.DeleteFile fn, true
	Repository.WriteOutput "Script", Now & " Writing to file " & fn, 0 

	objOTLFile.SaveToFile fn, 2
	objOTLFile.Close
	
	Repository.WriteOutput "Script", Now & " Done. Check the Error tab", 0 
	Repository.EnsureOutputVisible "Script"


end sub

main