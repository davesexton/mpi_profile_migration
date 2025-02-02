$source_file = 'PageGroupNATest117-Schema.htm'

$transform = New-Object -TypeName System.Xml.Xsl.XslCompiledTransform

#$writer = [system.xml.XmlWriter]::Create("bond_schema.xml");
$xls_path = 'C:\Projects\git\mpi_profile_migration\scripts\bond_schema.xml'
$xml_path = 'C:\Projects\git\mpi_profile_migration\scripts\temp.xml'
$xsl_path = 'C:\Projects\git\mpi_profile_migration\scripts\temp.xsl'

$xsl = [xml]@'
<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
          xmlns:o="urn:schemas-microsoft-com:office:office"
          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" 
          xmlns:x="urn:schemas-microsoft-com:office:excel"
          xmlns="urn:schemas-microsoft-com:office:spreadsheet">

<xsl:output method="xml"
            indent="yes" />

<xsl:template name="worksheets">
  <xsl:for-each select="//div">
    <Worksheet>
      <xsl:attribute name="ss:Name">
        <xsl:value-of select="./h1" />
      </xsl:attribute>
      <Table>
        <Column ss:AutoFitWidth="0" ss:Width="120" /> 
        <Column ss:AutoFitWidth="0" ss:Width="120"/> 
        <Column ss:AutoFitWidth="0" ss:Width="120"/> 
        <Column ss:AutoFitWidth="0" ss:Width="120"/> 
        <Column ss:AutoFitWidth="0" ss:Width="120"/>
        <Column ss:AutoFitWidth="0" ss:Width="60"/>
        <Row>
          <Cell><Data ss:Type="String">ROLE</Data></Cell>
          <Cell><Data ss:Type="String">ROLE TYPE</Data></Cell>
          <Cell><Data ss:Type="String">ATTRIBUTE</Data></Cell>
          <Cell><Data ss:Type="String">DESCRIPTION</Data></Cell>
          <Cell><Data ss:Type="String">TYPE</Data></Cell>
          <Cell><Data ss:Type="String">SIZE</Data></Cell>
         </Row>
         <xsl:for-each select="./table/tr[position()>1]">
           <Row>
             <Cell>
               <Data ss:Type="String">
                 <xsl:variable name="pos" select="position() + 2" />
                 <xsl:variable name="role" select="../tr[td[1]!='' and position() &gt; 1 and position() &lt; $pos][last()]/td[1]" />
                 <xsl:choose>
                   <xsl:when test="contains($role, '(')">
                     <xsl:value-of select="substring-before($role, '(')" />
                   </xsl:when>
                   <xsl:otherwise>
                     <xsl:value-of select="$role" />
                   </xsl:otherwise>
                 </xsl:choose>
               </Data>
             </Cell>
             <Cell>
               <Data ss:Type="String">
                 <xsl:variable name="pos" select="position() + 2" />
                 <xsl:variable name="type" select="../tr[td[1]!='' and position() &gt; 1 and position() &lt; $pos][last()]/td[1]" />
                 <xsl:choose>
                   <xsl:when test="contains($type, '(*)')">Multiple</xsl:when>
                   <xsl:when test="contains($type, '(N)')">Named</xsl:when>
                   <xsl:otherwise></xsl:otherwise>
                 </xsl:choose>        
               </Data>
             </Cell>
             <Cell>
               <Data ss:Type="String">
                 <xsl:value-of select="td[2]" />
               </Data>
             </Cell>
             <Cell>
               <Data ss:Type="String">
                 <xsl:value-of select="td[3]" />
               </Data>
             </Cell>
             <Cell>
               <Data ss:Type="String">
                 <xsl:choose>
                   <xsl:when test="substring(td[4], string-length(td[4])) = '/'">
                     <xsl:value-of select="substring(td[4], 0, string-length(td[4]))" />
                   </xsl:when>
                   <xsl:otherwise>
                     <xsl:value-of select="td[4]" />
                   </xsl:otherwise>
                 </xsl:choose>        
               </Data>
             </Cell>
             <Cell>
               <Data ss:Type="Number">
                 <xsl:value-of select="td[5]" />
               </Data>
             </Cell>
           </Row>
         </xsl:for-each>
       </Table>
     </Worksheet>
  </xsl:for-each>
</xsl:template>

<xsl:template match="/">
<xsl:processing-instruction name="mso-application">progid="Excel.Sheet"</xsl:processing-instruction>
<Workbook xmlns:html="http://www.w3.org/TR/REC-html40"
          xmlns:o="urn:schemas-microsoft-com:office:office"
          xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet" 
          xmlns:x="urn:schemas-microsoft-com:office:excel"
          xmlns="urn:schemas-microsoft-com:office:spreadsheet">

    <xsl:call-template name="worksheets" />
</Workbook>
</xsl:template>


</xsl:stylesheet>
'@

$xml = (Get-Content $source_file)
$xml = [regex]::Match($xml, '<body>(.|\r)+</body>').Value
$xml = $xml -Replace '(?<=<\w+) [^>]+', ''
$xml = $xml -Replace '&nbsp;', ''
$xml = $xml -Replace '&', 'and'
$xml = [xml]"<?xml version=`"1.0`"?>`n$xml"
$xml.Save($xml_path)
$xsl.Save($xsl_path)

#$xml = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xml)
#$xsl = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xsl)

$transform.Load($xsl_path)

$transform.Transform($xml_path, $xls_path)
Remove-Item $xml_path
Remove-Item $xsl_path

#$writer.close()

