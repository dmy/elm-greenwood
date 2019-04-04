# XML and pseudo-XML parser

An experimental XML parser with the following design goals:
* stack safe by using tail-call elimination
* tolerant to invalid XML documents as long as this does not impact performance
* fast by avoiding back-tracking and not escaping characters during parsing
* keep all the XML document information and order to allow to implement validators and pseudo-XML decoders
