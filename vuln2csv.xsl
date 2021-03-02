<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="text" encoding="iso-8859-1"/>

<!--Parameters for fields structure-->

	<xsl:param name="delim" select="string(',')" />
	<xsl:param name="quote" select="string('&quot;')" />
	<xsl:param name="break" select="string('&#xD;')" />
	<xsl:param name="linefeed" select="string('&#10;')" />
	<xsl:param name="space" select="string('&#x20;')" />
	<xsl:param name="max_cvs_field_length" select="32000" />


<!--Matching fields in knowledge base-->


	<xsl:template match="/">
			<xsl:text>"QID_CVE","CVE_ID"</xsl:text>
		<xsl:value-of select="$linefeed"/>
		<xsl:apply-templates select="KNOWLEDGE_BASE_VULN_LIST_OUTPUT/RESPONSE/VULN_LIST/VULN"/>
	</xsl:template>

	<xsl:template match="VULN">
		
	
		<xsl:value-of select="string('&quot;')"/>
		<xsl:call-template name="display_csv_field">
			<xsl:with-param name="field" select="QID" />
		</xsl:call-template>
		<xsl:value-of select="string('&quot;')"/>
		<xsl:value-of select="$delim"/>

		<xsl:value-of select="string('&quot;')"/>
		<xsl:call-template name="display_csv_field">
			<xsl:with-param name="field" select="CVE_LIST/CVE/ID" />
		</xsl:call-template>
		<xsl:value-of select="string('&quot;')"/>


		<xsl:value-of select="$linefeed" />

	</xsl:template>

  <!-- Template to escape csv field -->
	<xsl:template name="display_csv_field">
		<xsl:param name="field"/>
		<xsl:choose>
			<xsl:when test="contains($field,$quote)">
			<!-- Field contains a quote. We must enclose this field in quotes,
			and we must escape each of the quotes in the field value.
			-->
				<xsl:value-of select="$quote"/>
				<xsl:call-template name="escape_quotes">
					<xsl:with-param name="string" select="substring($field,0,$max_cvs_field_length)" />
				</xsl:call-template>
				<xsl:value-of select="$quote"/>
			</xsl:when>
			<xsl:when test="contains($field,',' ) or contains($field,$linefeed)">
			<!-- Field contains a comma and/or a linefeed.
			We must enclose this field in quotes.
			-->
				<xsl:value-of select="concat($quote,substring($field,0,$max_cvs_field_length),$quote)"/>
			</xsl:when>
			<xsl:otherwise>
			<!-- No need to enclose this field in quotes.-->
				<xsl:value-of select="substring($field,0,$max_cvs_field_length)" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!-- Helper for escaping CSV field -->
	<xsl:template name="escape_quotes">
		<xsl:param name="string" />
		<xsl:value-of select="substring-before($string,$quote)" />
		<xsl:value-of select="$quote"/>
		<xsl:value-of select="$quote"/>
		<xsl:variable name="substring_after_first_quote" select="substring-after($string,$quote)" />
		<xsl:choose>
			<xsl:when test="not(contains($substring_after_first_quote,$quote))">
				<xsl:value-of select="$substring_after_first_quote" />
			</xsl:when>
			<xsl:otherwise>
			<!-- The substring after the first quote contains a quote.
			So, we call ourself recursively to escape the quotes
			in the substring after the first quote.
			-->
				<xsl:call-template name="escape_quotes">
					<xsl:with-param name="string" select="$substring_after_first_quote"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
</xsl:stylesheet>