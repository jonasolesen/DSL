package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Function
import dk.sdu.mmmi.typescriptdsl.FunctionCreate
import dk.sdu.mmmi.typescriptdsl.FunctionDelete
import dk.sdu.mmmi.typescriptdsl.FunctionRead
import dk.sdu.mmmi.typescriptdsl.FunctionSelect
import dk.sdu.mmmi.typescriptdsl.FunctionUpdate
import dk.sdu.mmmi.typescriptdsl.MaybeAttribute
import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.TableFunction
import java.util.List

import static extension dk.sdu.mmmi.generator.Helpers.*

class DelegateGenerator implements TableFunctionGenerator {

	override generate(List<Pair<Table, TableFunction>> entries) '''
		type ClientPromise<T, Args, Payload> = CheckSelect<Args, Promise<T | null>, Promise<Payload | null>>
		
		«FOR entry : entries SEPARATOR '\n'»
			«generateDelegate(entry.key, entry.value)»
		«ENDFOR»
		
		«generateClient(entries.map[key])»
	'''

	private def generateDelegate(Table table, TableFunction tableFunction) '''
		interface «table.name»Delegate {
			«IF tableFunction !== null»
				«FOR f : tableFunction.functions»
					«f.name + f.body.generateSignature(table) + f.body.generateReturnType(table)»
				«ENDFOR»
			«ENDIF»
			findFirst<T extends «table.name»Args>(args: SelectSubset<T, «table.name»Args>): ClientPromise<«table.name», T, «table.name»GetPayload<T>>
			delete(where: WhereInput<«table.name»>): Promise<number>
			create(args: { data: «table.name»CreateInput }): Promise<«table.name»>
			update(args: { where: WhereInput<«table.name»>, data: Partial<«table.name»CreateInput> }): Promise<number>
		}
	'''

	private def generateClient(List<Table> tables) '''
		export interface Client {
			«FOR t : tables»
				«t.name.toCamelCase»: «t.name»Delegate
			«ENDFOR»
		}	
	'''

	private def generateSignature(Function function, Table table) {
		val List<MaybeAttribute> parameters = switch function {
			FunctionCreate: function.data.parameters
			FunctionRead: function.where.parameters
			FunctionUpdate: function.where.parameters
			FunctionDelete: function.where.parameters
			default: null
		}

		'''(«IF parameters !== null && parameters.exists[attribute !== null] »args: { «parameters.generateInputParameters» }«ENDIF»): '''
	}

	private def generateInputParameters(List<MaybeAttribute> attributes) {
		attributes.filter[attribute !== null].map [
			'''«attribute.name»: «attribute.type.asString»'''
		].join(', ')
	}

	private def generateReturnType(Function function, Table table) {
		// If read or create, use payload - else use number
		val Pair<Boolean, FunctionSelect> selectEntry = switch function {
			FunctionRead: true -> function.select
			FunctionCreate: true -> function.select
			default: false -> null
		}

		if(!selectEntry.key) return '''Promise<number>'''

		val returnType = switch selectEntry {
			case selectEntry.value === null: 'null'
			default: '''{ select: { «selectEntry.value.attributes.map[name + ': true'].join(', ')» } }'''
		}

		'''Promise<«table.name.toPascalCase»GetPayload<«returnType»>>'''
	}
}
