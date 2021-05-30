package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Function
import dk.sdu.mmmi.typescriptdsl.FunctionCreate
import dk.sdu.mmmi.typescriptdsl.FunctionDelete
import dk.sdu.mmmi.typescriptdsl.FunctionRead
import dk.sdu.mmmi.typescriptdsl.FunctionSelect
import dk.sdu.mmmi.typescriptdsl.FunctionUpdate
import dk.sdu.mmmi.typescriptdsl.Table
import java.util.List

import static extension dk.sdu.mmmi.generator.Helpers.*

class FunctionGenerator implements IntermediateGenerator {

	override generate(List<Table> tables) '''
		export interface FunctionData {
			type: 'findFirst' | 'delete' | 'create' | 'update'
			where?: Record<string, unknown>
			data?: Record<string, unknown>
			select?: Record<string, unknown>
		}
		
		export const tableFunctions: { [key in keyof Client]?: Record<string, FunctionData> } = {
			«FOR t : tables.filter[functions.length > 0] SEPARATOR ','»«t.name.toCamelCase»: {
				«FOR entry : t.functions.map[name -> body] SEPARATOR ','»
					«entry.key»: {
						«t.generateFunctionData(entry)»
					}
				«ENDFOR»
			}
			«ENDFOR»
		}
	'''

	private def generateFunctionData(Table table, Pair<String, Function> entry) '''
		type: «entry.value.asClientCRUD»,
		«entry.value.generateWhere»
		«entry.value.generateSelect»
		«entry.value.generateData»
	'''

	private def generateWhere(Function function) {
		val parameters = switch function {
			FunctionRead: function.where
			FunctionUpdate: function.where
			FunctionDelete: function.where
			default: null
		}

		if(parameters === null) return ''

		'''
			where: {
				«FOR c : parameters.parameters.filter[constraint !== null].map[constraint] SEPARATOR ',\n'»«c.asQueryObject»«ENDFOR»
			},
		'''
	}

	private def generateSelect(Function function) {
		val FunctionSelect select = switch function {
			FunctionCreate: function.select
			FunctionRead: function.select
			default: null
		}
		
		if(select === null) return ''

		'''
			select: {
				«FOR a : select.attributes SEPARATOR ',\n'»«a.name»: true«ENDFOR»
			},
		'''
	}
	
	private def generateData(Function function) {
		val data = switch function {
			FunctionCreate: function.data.parameters.filter[record !== null].map[record].toList
			FunctionUpdate: function.data.records
			default: null
		}
		
		if(data === null || data.length === 0) return ''

		'''
			data: {
				«FOR r : data SEPARATOR ',\n'»«r.key.name»: «r.value.asString»«ENDFOR»
			},
		'''
	}

	private def asClientCRUD(Function function) {
		switch function {
			FunctionCreate: 'create'
			FunctionRead: 'findFirst'
			FunctionUpdate: 'update'
			FunctionDelete: 'delete'
		}.singleQuotes
	}
}
