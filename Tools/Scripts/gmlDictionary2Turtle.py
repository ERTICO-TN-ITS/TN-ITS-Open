# Script for converting GML Dictionary files to OWL Ontology (Turtle)

import xml.etree.ElementTree as ET
from rdflib import Graph, Namespace, URIRef,  Literal
from rdflib.namespace import RDF, RDFS, XSD, SKOS, OWL, DC
import glob

dictFolder = 'C:\\DATA\\GitHub\\ERTICO-TN-ITS\\TN-ITS-Open\\XSD\\codelists\\'
ttlFile = 'C:\\DATA\\GitHub\\ERTICO-TN-ITS\\TN-ITS-Open\\OWL\\codelists\\tnits-codelists.ttl'

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

ont = URIRef(strCodeURI + '#codevalues')
g.add((ont, RDF.type, OWL.Ontology))
g.add((ont, OWL.imports, URIRef(strSKOS)))
g.add((ont, DC.creator, Literal('TN-ITS', datatype=XSD.string)))
g.add((ont, DC.description, Literal('Code list values for TN-ITS code lists', datatype=XSD.string)))
g.add((ont, DC.title, Literal('TN-ITS Codes', datatype=XSD.string)))

#------------------------------ Parse XML Files ---------------------------------------
for f in glob.glob(dictFolder + '*.xml'):
    tree = ET.parse(f)
    root = tree.getroot()

    d = root.find(nsGML + 'description').text
    print('description: ' + d)
    di = root.find(nsGML + 'identifier').text
    print('Dictionary identifier: ' + di)

    # -------------------- Code list class and concept scheme
    cl = URIRef(strCodeURI + '#' + di.replace('Code',''))
    g.add((cl,RDF.type,OWL.Class))
    g.add((cl,RDFS.subClassOf,URIRef(strCoreURI + '#tnitsCodeList')))
    g.add((cl,SKOS.definition,Literal(d,datatype=XSD.string)))
    g.add((cl,RDFS.label,Literal(di.replace('Code',''), datatype=XSD.string)))
    cs = URIRef(strCodeURI + '#' + di)
    g.add((cs,RDF.type,SKOS.ConceptScheme))
    g.add((cs,DC.isFormatOf,cl))
    g.add((cs,SKOS.definition,Literal(d,datatype=XSD.string)))

    #Set filename
    #ttlFile = ttlFile + di + '.ttl'

    i = root.find(nsGML + 'identifier')
    dcs = i.get('codeSpace')
    print('codesPace: ' + dcs)
    print('-----------------------')

    for de in root.findall(nsGML + 'dictionaryEntry'):
        dfn = de.find(nsGML + 'Definition')
        id = dfn.get(nsGML + 'id')
        print('id: ' + str(id))
        d = dfn.find(nsGML + 'description').text
        print('description: ' + d)
        ei = dfn.find(nsGML + 'identifier').text
        print('identifier: ' + ei)
        i = dfn.find(nsGML + 'identifier')
        ecs = i.get('codeSpace')
        print('codesPace: ' + ecs)

        clv = URIRef(strCodeURI + '#' + di.replace('Code','') + '.' + ei)
        g.add((clv,RDF.type,cl))
        g.add((clv,RDF.type,SKOS.Concept))
        g.add((clv,SKOS.inScheme,cs))
        g.add((clv,SKOS.definition,Literal(d,datatype=XSD.string)))
        g.add((clv,RDFS.label,Literal(ei, datatype=XSD.string)))

#print(g.serialize(format='turtle'))
print(g.serialize(destination=ttlFile, format='turtle'))