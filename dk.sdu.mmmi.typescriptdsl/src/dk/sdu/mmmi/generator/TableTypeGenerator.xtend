package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Attribute
import dk.sdu.mmmi.typescriptdsl.IntType
import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.TableType
import java.util.List

import static extension dk.sdu.mmmi.generator.Helpers.*

class TableTypeGenerator implements IntermediateGenerator {
	override generate(List<Table> tables) {
		tables.filter(Table).map[generateTypes].join("\n")
	}

	private def CharSequence generateTypes(Table table) {
		newArrayList(
			table.generateTable,
			table.generateFindArgs,
			table.generateSelect,
			table.generateInclude,
			table.generateGetPayload,
			table.generateCreateInputType
		).join('\n')
	}

	private def hasRelations(Table table) {
		table.attributes.exists[it|it.type instanceof TableType]
	}

	private def generateTable(Table table) '''
		export type «table.name» = «IF table.superType !== null»«table.superType.name» & «ENDIF»{
			«FOR a : table.attributes»
				«a.generateAttribute»
			«ENDFOR»
		}
	'''

	private def generateFindArgs(Table table) '''
		export type «table.name»Args = {
			where?: WhereInput<«table.name»>
			select?: «table.name»Select | null
			«IF table.hasRelations»include?: «table.name»Include | null«ENDIF»
		}
	'''

	private def generateInclude(Table table) {
		if(!table.hasRelations) return ''
		'''
			export type «table.name»Include = {
				«FOR a : table.attributes.filter[it | it.type instanceof TableType]»
					«a.name»?: boolean«a.type instanceof TableType ? " | " + a.name.toPascalCase + "Args" : ""»
				«ENDFOR»
			}
		'''
	}

	private def generateSelect(Table table) '''
		export type «table.name»Select = {
			«FOR a : table.attributes.filter[!(type instanceof TableType)]»
				«a.name»?: boolean«a.type instanceof TableType ? " | " + a.name.toPascalCase + "Args" : ""»
			«ENDFOR»
		}
	'''

	private def generateAttribute(Attribute attribute) {
		if(attribute.type instanceof TableType) return ""

		val typeName = attribute.type.asString

		'''«attribute.name»: «typeName»«attribute.optional ? ' | null'»'''
	}

	private def generateGetPayload(Table table) {
		val hasRelations = table.hasRelations
		'''
			export type «table.name»GetPayload<
				S extends boolean | null | undefined | «table.name»Args,
				U = keyof S
			> = S extends true
				? «table.name» : S extends undefined
					? never : S extends «table.name»Args
						? «hasRelations ? table.generatePayloadInclude : table.generatePayloadSelect»
						«hasRelations ? ': ' + table.generatePayloadSelect»
				: «table.name»
		'''
	}

	private def generatePayloadInclude(Table table) {
		if(!table.hasRelations) return ''
		'''
			'include' extends U
				? «table.name» & {
					[P in TrueKeys<S['include']>] :
					«FOR a : table.attributes.filter[it.type instanceof TableType]»
						P extends '«a.name»' ? «a.name.toPascalCase»GetPayload<S['include'][P]> «a.optional ? '| null'» :
					«ENDFOR»
					never
				}
		'''
	}

	private def generatePayloadSelect(Table table) '''
		'select' extends U
		? {
			[P in TrueKeys<S['select']>]: P extends keyof «table.name» ? «table.name»[P] :
			«FOR a : table.attributes.filter[it.type instanceof TableType]»
				P extends '«a.name»' ? «a.name.toPascalCase»GetPayload<S['select'][P]> «a.optional ? '| null'» :
			«ENDFOR»
			never
		} : «table.name»
	'''

	private def generateCreateInputType(Table table) '''
		export type «table.name»CreateInput = {
			«FOR a : table.attributes»
				«a.generateAttributeInput»
			«ENDFOR»
		}
	'''

	private def generateAttributeInput(Attribute attr) {
		var name = attr.name
		var type = attr.type
		if (attr.type instanceof TableType) {
			val table = (attr.type as TableType).table
			val primary = table.primaryKey
			name = '''«table.name.toCamelCase»«primary.name.toPascalCase»'''
			type = primary.type
		}

		val optional = attr.optional || attr.primary && attr.type instanceof IntType

		'''«name»«IF optional»?«ENDIF»: «type.asString»«IF attr.optional» | null«ENDIF»'''
	}
}
