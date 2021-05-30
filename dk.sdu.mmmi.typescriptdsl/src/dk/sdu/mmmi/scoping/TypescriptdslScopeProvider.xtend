package dk.sdu.mmmi.scoping

import dk.sdu.mmmi.typescriptdsl.Attribute
import dk.sdu.mmmi.typescriptdsl.Function
import dk.sdu.mmmi.typescriptdsl.FunctionRead
import dk.sdu.mmmi.typescriptdsl.FunctionSelect
import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.TableFunction
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.scoping.impl.SimpleScope

import static dk.sdu.mmmi.generator.Helpers.*
import static dk.sdu.mmmi.typescriptdsl.TypescriptdslPackage.Literals.*
import static org.eclipse.xtext.EcoreUtil2.*

/** 
 * This class contains custom scoping description.
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class TypescriptdslScopeProvider extends AbstractTypescriptdslScopeProvider {
	override getScope(EObject context, EReference reference) {
		val function = getContainerOfType(context, Function)
		if(function !== null) return context.getFunctionScope(function)

		if(getContainerOfType(context, Table) === null) return super.getScope(context, reference)

		switch reference {
			case reference.name === 'left',
			case FIELD__ATTRIBUTE: {
				val attribute = getContainerOfType(context, Attribute)
				val alias = EObjectDescription.create(QualifiedName.create('it'), attribute)

				new SimpleScope(newArrayList(alias))
			}
			default:
				super.getScope(context, reference)
		}
	}

	private def getFunctionScope(EObject context, Function function) {
		val table = getContainerOfType(context, TableFunction).table

		val includeKeys = switch function {
			FunctionSelect,
			FunctionRead: true
			default: false
		}

		Scopes.scopeFor(scalars(table.attributes, includeKeys))
	}
}
