# Script for converting GML Dictionary files to OWL Ontology (Turtle)

import xml.etree.ElementTree as ET
from rdflib import Graph, Namespace, URIRef,  Literal
from rdflib.namespace import RDF, RDFS, XSD, SKOS, OWL, DC,DCTERMS
import glob

dictFolder = 'C:\\DATA\\GitHub\\ERTICO-TN-ITS\\TN-ITS-Open\\XSD\\codelists\\'
ttlPath = 'C:\\DATA\\GitHub\\ERTICO-TN-ITS\\TN-ITS-Open\\OWL\\codelists\\'
ghPath = 'https://raw.githubusercontent.com/ERTICO-TN-ITS/TN-ITS-Open/master/OWL/codelists/'
ttlFile = ttlPath + 'allcodes.ttl'

nsGML = '{http://www.opengis.net/gml/3.2}'
strCoreNs = 'tnits'
strCoreURI = 'http://spec.tn-its.eu/owl/tnits-owl'
strCodeNs = 'codes'
strCodeURI = 'http://spec.tn-its.eu/codelists/'   #strCoreURI + '/codelists'
strSKOS = 'http://www.w3.org/2004/02/skos/core'


def ontoHeader(gr,oURI,oTitle,oDescription):
    #Add header to ontology
    gr.bind('dc', Namespace('http://purl.org/dc/elements/1.1/'))
    gr.bind('owl', Namespace('http://www.w3.org/2002/07/owl#'))
    gr.bind('rdf', Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#'))
    gr.bind('xml', Namespace('http://www.w3.org/XML/1998/namespace'))
    gr.bind('xsd', Namespace('http://www.w3.org/2001/XMLSchema#'))
    gr.bind('rdfs', Namespace('http://www.w3.org/2000/01/rdf-schema#'))
    gr.bind('skos', Namespace(strSKOS + '#'))
    gr.bind('dcterms', Namespace('http://purl.org/dc/terms/'))
    gr.bind('reg', Namespace('http://purl.org/linked-data/registry#'))
    gr.bind(strCoreNs, Namespace(strCoreURI + '#'))
    gr.bind(strCodeNs, Namespace(strCodeURI))

    gr.add((oURI, RDF.type, OWL.Ontology))
    gr.add((oURI, OWL.imports, URIRef(strSKOS)))
    gr.add((oURI, DC.creator, Literal('TN-ITS', datatype=XSD.string)))
    gr.add((oURI, DC.description, Literal(oDescription, datatype=XSD.string)))
    gr.add((oURI, DC.title, Literal(oTitle, datatype=XSD.string)))


# -------------------------- Create graph for the combined ontology  ----------------------------------
g = Graph()
#Prefixes
om = URIRef(strCodeURI + '#allcodes')
ontoHeader(g,om,'TN-ITS Codes','Code list values for TN-ITS code lists')

#------------------------------ Parse XML Files (GML Dictionaries) ---------------------------------------
for f in glob.glob(dictFolder + '*.xml'):
    print('')
    print('-------- Start reading GML Dictionary: ' + f + ' ---------------')
    tree = ET.parse(f)
    root = tree.getroot()
    d = root.find(nsGML + 'description').text
    i = root.find(nsGML + 'identifier')
    di = i.text
    dcs = i.get('codeSpace') + di
    print('Dictionary identifier: ' + di)
    print('Dictionary codespace: ' + dcs)
    print('Dictionary description: ' + d)

    #New individual code list ontology
    g_ind = Graph()
    o_ind = URIRef(dcs + 'Vocabulary')
    ontoHeader(g_ind, o_ind, 'TN-ITS Codes for ' + di, d)

    # -------------------- Code list Class (without 'Code' suffix) and Concept Scheme (with 'Code' suffix)
    cl = URIRef(strCoreURI + '#' + di.replace('Code',''))                               #Remove 'Code' from the code list class' URI
    di_m = di.replace('Extensions', '')                                                 #Find parent code list name for extensions
    clm = URIRef(strCoreURI + '#' + di_m.replace('Code', ''))                           #Remove 'Code' from the parent code list class' URI
    #Add class and subclass statement if the name ends with "Extension". Other (but empty) code lists are defined in the main tn-its.owl
    if di.endswith('Extensions'):
        g_ind.add((cl, RDF.type, OWL.Class))                                            #The code list as a class
        g_ind.add((cl, RDFS.subClassOf, URIRef(strCoreURI + '#tnitsCodeList')))         #Subclass of the core TN-ITS Code list
        g_ind.add((cl,RDFS.subClassOf,clm))                                             #Extension class as subclass of the official codelist (di_m)
        g_ind.add((cl,SKOS.definition,Literal(d,datatype=XSD.string)))                  #Code list definition
        g_ind.add((cl,RDFS.label,Literal(di.replace('Code',''), datatype=XSD.string)))  #Code list label (name without 'Code')
    # ---------------------- Concept Scheme
    cs = URIRef(dcs)                                                                    #Concept Scheme with 'Code' suffix
    g_ind.add((cs,RDF.type,SKOS.ConceptScheme))                                         #The code list as a ConceptSchem (name with 'Code')
    g_ind.add((cs,DCTERMS.isFormatOf,cl))                                               #Reference from the ConceptScheme to the class
    g_ind.add((cs,SKOS.definition,Literal(d,datatype=XSD.string)))                      #Definition of the ConceptScheme, same as for the class
    g_ind.add((cs,DCTERMS.publisher, URIRef('https://tn-its.eu/')))
    g_ind.add((cs,DCTERMS.creator, URIRef('https://tn-its.eu/')))
    g_ind.add((cs,DCTERMS.identifier, Literal(di,datatype=XSD.token)))
    g_ind.add((cs,DCTERMS.provenance, Literal('Derived from GML dictionary',datatype=XSD.string)))
    g_ind.add((cs,DCTERMS.source, Literal(cs + '.xsd',datatype=XSD.anyURI)))

    # -------------------- Code values as individuals of code list Class and Concept Scheme
    for de in root.findall(nsGML + 'dictionaryEntry'):
        print('--------- Dictionary entry --------------')
        dfn = de.find(nsGML + 'Definition')
        ei = dfn.find(nsGML + 'identifier').text
        d = dfn.find(nsGML + 'description').text
        print('description: ' + d)
        print('identifier: ' + ei)

        #TBD:
        #URI for the code list value: Without "Extension"
        #to make identifiers persisent if the value is later accepted for inclusion in the main list
        clv = URIRef(dcs.replace('Extensions', '') + '#' + ei)                                                    #Value URI
        g_ind.add((clv,RDF.type,cl))                                                    #Add the code value as an individual of the code list class
        g_ind.add((clv,RDF.type,SKOS.Concept))                                          #Add the code value as a concept
        g_ind.add((clv,SKOS.inScheme,cs))                                               #Add reference to the ConceptScheme
        g_ind.add((clv,RDFS.isDefinedBy,cs))                                            #Add reference to the ConceptScheme
        g_ind.add((clv,SKOS.definition,Literal(d,datatype=XSD.string)))                 #Code value defintion
        g_ind.add((clv,RDFS.label,Literal(ei, datatype=XSD.string)))
        g_ind.add((clv,SKOS.prefLabel,Literal(ei, datatype=XSD.string)))
        g_ind.add((clv,DCTERMS.identifier,Literal(ei, datatype=XSD.string)))
        g_ind.add((clv, DCTERMS.provenance, Literal('Derived from GML dictionary', datatype=XSD.string)))
        g_ind.add((clv,SKOS.topConceptOf,cs))
        if di.endswith('Extensions'):
            g_ind.add((clv, URIRef('http://purl.org/linked-data/registry#status'), URIRef('http://purl.org/linked-data/registry#statusSubmitted')))
        else:
            g_ind.add((clv, URIRef('http://purl.org/linked-data/registry#status'), URIRef('http://purl.org/linked-data/registry#statusStable')))
        g_ind.add((cs,SKOS.hasTopConcept,clv))


    #Print individual file
    #print(g_ind.serialize(format='turtle'))
    ttl_ind = ttlPath + di + '.ttl'
    g_ind.serialize(destination=ttl_ind, format='turtle')
    #Add "imports" for this individual file to the combined 'AllCodes' ontology
    g.add((om, OWL.imports, URIRef(ghPath + di + '.ttl')))

#Print combined file
#print('')
#print('-------- Combined ontology:  ---------------')
#print(g.serialize(format='turtle'))
g.serialize(destination=ttlPath + 'AllCodes.ttl', format='turtle')
