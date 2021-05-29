package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Add
import dk.sdu.mmmi.typescriptdsl.And
import dk.sdu.mmmi.typescriptdsl.Attribute
import dk.sdu.mmmi.typescriptdsl.BooleanConstraint
import dk.sdu.mmmi.typescriptdsl.Comparison
import dk.sdu.mmmi.typescriptdsl.Constraint
import dk.sdu.mmmi.typescriptdsl.Div
import dk.sdu.mmmi.typescriptdsl.Expression
import dk.sdu.mmmi.typescriptdsl.Field
import dk.sdu.mmmi.typescriptdsl.Function
import dk.sdu.mmmi.typescriptdsl.FunctionCreate
import dk.sdu.mmmi.typescriptdsl.FunctionDelete
import dk.sdu.mmmi.typescriptdsl.FunctionRead
import dk.sdu.mmmi.typescriptdsl.FunctionReadParameters
import dk.sdu.mmmi.typescriptdsl.FunctionSelect
import dk.sdu.mmmi.typescriptdsl.FunctionUpdate
import dk.sdu.mmmi.typescriptdsl.Mul
import dk.sdu.mmmi.typescriptdsl.NumberExp
import dk.sdu.mmmi.typescriptdsl.Or
import dk.sdu.mmmi.typescriptdsl.Parenthesis
import dk.sdu.mmmi.typescriptdsl.RegexConstraint
import dk.sdu.mmmi.typescriptdsl.StringConstraint
import dk.sdu.mmmi.typescriptdsl.Sub
import dk.sdu.mmmi.typescriptdsl.Table
import java.util.List

import static extension dk.sdu.mmmi.generator.Helpers.*

class DelegateGenerator implements IntermediateGenerator {

	override generate(List<Table> tables) '''
		type ClientPromise<T, Args, Payload> = CheckSelect<Args, Promise<T | null>, Promise<Payload | null>>
		
		«FOR t : tables SEPARATOR '\n'»
			«t.generateDelegate»
		«ENDFOR»
		
		«generateClient(tables)»
	'''

	private def generateDelegate(Table table) '''
		interface «table.name»Delegate {
			«FOR f : table.functions»
				«f.name + f.body.generateSignature(table) + f.body.generateReturnType(table)»
			«ENDFOR»
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
		val parameters = switch function {
			FunctionRead: function.where
			FunctionUpdate: function.where
			FunctionDelete: function.where
			default: null
		}

		'''(«IF parameters !== null && parameters.parameters.exists[attribute !== null] »args: { «parameters.generateReadParameters» }«ENDIF»): '''
	}

	private def generateReadParameters(FunctionReadParameters read) {
		read.parameters.filter[attribute !== null && constraint === null].map [
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
		
		return '''Promise<«table.name.toPascalCase»GetPayload<«returnType»>>'''
		
		
//		if(select.value === null)
//		
//		val Pair<Boolean, String> returnType = switch function {
//			FunctionRead: true -> '''{ select: { «function.select.attributes.map[name + ': true'].join(', ')» } }'''
//			FunctionCreate: true -> '''{ select: { «function.select.attributes.map[name + ': true'].join(', ')» } }'''
//			FunctionUpdate,
//			FunctionDelete: false -> 'number'
//			case (function as FunctionRead).select === null: false -> 'null'
//			default: true -> '''{ select: { «(function as FunctionRead).select.attributes.map[name + ': true'].join(', ')» } }'''
//		}
//
//		// If update or delete, return number - else use payload
//		if(!returnType.key) return '''Promise<«returnType.value»>'''
//		return '''Promise<«table.name.toPascalCase»GetPayload<«returnType.value»>>'''
	}

	def CharSequence constraints(Constraint cons, Attribute current) {
		switch cons {
			RegexConstraint: '''new RegExp(/«cons.value»/g).test(value.«current.name»)'''
			StringConstraint:
				cons.right === 'equals'
					? '''«cons.left.name» = «cons.right»''' : '''«cons.left.name».includes(«cons.right»)'''
			BooleanConstraint: '''«cons.left.name» = «cons.right»'''
			Comparison: '''«cons.left.printExp» «cons.operator» «cons.right.printExp»'''
			Or: '''«cons.left.constraints(current)» || «cons.right.constraints(current)»'''
			And: '''«cons.left.constraints(current)» && «cons.right.constraints(current)»'''
			default:
				"unknown"
		}
	}

	def CharSequence printExp(Expression exp) {
		switch exp {
			Add: '''«exp.left.printExp» + «exp.right.printExp»'''
			Sub: '''«exp.left.printExp» - «exp.right.printExp»'''
			Mul: '''«exp.left.printExp» * «exp.right.printExp»'''
			Div: '''«exp.left.printExp» / «exp.right.printExp»'''
			Parenthesis: '''(«exp.exp.printExp»)'''
			NumberExp: '''«exp.value»'''
			Field: '''value.«exp.attribute.name»'''
			default:
				throw new Exception()
		}
	}
}
