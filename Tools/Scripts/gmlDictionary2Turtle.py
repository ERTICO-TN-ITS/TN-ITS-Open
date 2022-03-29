# Script for converting GML Dictionary files to OWL Ontology (Turtle)

import xml.etree.ElementTree as ET
from rdflib import Graph, Namespace, URIRef,  Literal
from rdflib.namespace import RDF, RDFS, XSD, SKOS, OWL, DC,DCTERMS
import glob

dictFolder = 'C:\\DATA\\GitHub\\ERTICO-TN-ITS\\TN-ITS-Open\\XSD\\codelists\\'
ttlPath = 'C:\\DATA\\GitHub\\ERTICO-TN-ITS\\TN-ITS-Open\\OWL\\codelists\\'
ttlFile = ttlPath + 'allcodes.ttl'

nsGML = '{http://www.opengis.net/gml/3.2}'
strCoreNs = 'tnits'
strCoreURI = 'http://spec.tn-its.eu/owl/tnits-owl'
strCodeNs = 'codes'
strCodeURI = strCoreURI + '/codelists'
strSKOS = 'http://www.w3.org/2004/02/skos/core'


# -------------------------- Create graph ontology ----------------------------------
g = Graph()
#Prefixes
g.bind('dc', Namespace('http://purl.org/dc/elements/1.1/'))
g.bind('owl', Namespace('http://www.w3.org/2002/07/owl#'))
g.bind('rdf', Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#'))
g.bind('xml', Namespace('http://www.w3.org/XML/1998/namespace'))
g.bind('xsd', Namespace('http://www.w3.org/2001/XMLSchema#'))
g.bind('rdfs', Namespace('http://www.w3.org/2000/01/rdf-schema#'))
g.bind('skos', Namespace(strSKOS + '#'))
g.bind('dcterms', Namespace('http://purl.org/dc/terms/'))
g.bind(strCoreNs, Namespace(strCoreURI + '#'))
g.bind(strCodeNs, Namespace(strCodeURI + '#'))

ont = URIRef(strCodeURI + '#allcodes')
g.add((ont, RDF.type, OWL.Ontology))
g.add((ont, OWL.imports, URIRef(strSKOS)))
g.add((ont, DC.creator, Literal('TN-ITS', datatype=XSD.string)))
g.add((ont, DC.description, Literal('Code list values for TN-ITS code lists', datatype=XSD.string)))
g.add((ont, DC.title, Literal('TN-ITS Codes', datatype=XSD.string)))

#------------------------------ Parse XML Files (GML Dictionaries) ---------------------------------------
for f in glob.glob(dictFolder + '*.xml'):
    print('')
    print('-------- Start reading GML Dictionary: ' + f + ' ---------------')
    tree = ET.parse(f)
    root = tree.getroot()
    d = root.find(nsGML + 'description').text
    print('Dictionary description: ' + d)
    di = root.find(nsGML + 'identifier').text
    print('Dictionary identifier: ' + di)

    # -------------------- Code list class and concept scheme
    print('Dictionary URI: ' + strCoreURI + '#' + di.replace('Code',''))
    cl = URIRef(strCoreURI + '#' + di.replace('Code',''))                           #Remove 'Code' from the code list class' URI
    di_m = di.replace('Extensions', '')                                             #Find main code list name for extensions
    clm = URIRef(strCoreURI + '#' + di_m.replace('Code', ''))                       #Remove 'Code' from the main code list class' URI
    if di.endswith('Extensions'):
        # Add class and subclass statement if the name ends with "Extension". Other (but empty) code lists are defined in the main tn-its.owl
        g.add((cl, RDF.type, OWL.Class))                                            #The code list as a class
        g.add((cl, RDFS.subClassOf, URIRef(strCoreURI + '#tnitsCodeList')))         #Subclass of the core TN-ITS Code list
        g.add((cl,RDFS.subClassOf,clm))                                             #Extension lis as subclass of the main codelist (di_m)
        g.add((cl,SKOS.definition,Literal(d,datatype=XSD.string)))                  #Code list definition
        g.add((cl,RDFS.label,Literal(di.replace('Code',''), datatype=XSD.string)))  #Code list label (name without 'Code')
    cs = URIRef(strCodeURI + '#' + di)
    g.add((cs,RDF.type,SKOS.ConceptScheme))                                         #The code list as a ConceptSchem (name with 'Code')
    g.add((cs,DCTERMS.isFormatOf,cl))                                               #Reference from the ConceptScheme to the class
    g.add((cs,SKOS.definition,Literal(d,datatype=XSD.string)))                      #Definition of the ConceptScheme, same as for the class
    i = root.find(nsGML + 'identifier')
    #dcs = i.get('codeSpace')
    #print('Dictionary codespace: ' + dcs + di)

    # -------------------- Code values
    for de in root.findall(nsGML + 'dictionaryEntry'):
        print('--------- Dictionary entry --------------')
        dfn = de.find(nsGML + 'Definition')
        id = dfn.get(nsGML + 'id')
        print('id: ' + str(id))
        d = dfn.find(nsGML + 'description').text
        print('description: ' + d)
        ei = dfn.find(nsGML + 'identifier').text
        print('identifier: ' + ei)
        i = dfn.find(nsGML + 'identifier')
        #ecs = i.get('codeSpace')
        #print('codespace: ' + ecs)
        #URI for the code list value: Without "Extension"
        #to make identifiers persisent if the value is later accepted for inclusion in the main list
        print('URI: ' + strCodeURI + '#' + di_m.replace('Code','') + '.' + ei)
        clv = URIRef(strCodeURI + '#' + di_m.replace('Code','') + '.' + ei)         #Remove 'Code' from the code value URI
        g.add((clv,RDF.type,cl))                                                    #Add the code value as an individual of the code list class
        g.add((clv,RDF.type,SKOS.Concept))                                          #Add the code value as a concept
        g.add((clv,SKOS.inScheme,cs))                                               #Add reference to the ConceptScheme
        g.add((clv,SKOS.definition,Literal(d,datatype=XSD.string)))                 #Code value defintion
        g.add((clv,RDFS.label,Literal(ei, datatype=XSD.string)))                    #Code value label

#Print combined file
#print(g.serialize(format='turtle'))
print(g.serialize(destination=ttlFile, format='turtle'))