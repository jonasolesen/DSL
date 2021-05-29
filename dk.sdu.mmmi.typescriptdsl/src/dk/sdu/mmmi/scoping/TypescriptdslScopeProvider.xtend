package dk.sdu.mmmi.scoping

import dk.sdu.mmmi.typescriptdsl.Attribute
import dk.sdu.mmmi.typescriptdsl.Function
import dk.sdu.mmmi.typescriptdsl.FunctionReadParameters
import dk.sdu.mmmi.typescriptdsl.FunctionWriteParameters
import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.TableType
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.naming.QualifiedName
import org.eclipse.xtext.resource.EObjectDescription
import org.eclipse.xtext.scoping.Scopes
import org.eclipse.xtext.scoping.impl.SimpleScope

import static dk.sdu.mmmi.typescriptdsl.TypescriptdslPackage.Literals.*
import static org.eclipse.xtext.EcoreUtil2.*

/** 
 * This class contains custom scoping description.
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class TypescriptdslScopeProvider extends AbstractTypescriptdslScopeProvider {
	override getScope(EObject context, EReference reference) {
		val table = getContainerOfType(context, Table)
		if(table === null) return super.getScope(context, reference)
		val scalars = table.attributes.filter[!(type instanceof TableType)]
		val scalarsWithoutKeys = scalars.filter[!primary]

		switch context {
			Function,
			FunctionReadParameters: return Scopes.scopeFor(scalars)
			FunctionWriteParameters: return Scopes.scopeFor(scalarsWithoutKeys)
		}

		return switch reference {
			case FUNCTION_SELECT__ATTRIBUTES:
				Scopes.scopeFor(scalars)
			case reference.name === 'left',
			case FIELD__ATTRIBUTE: {
				if (getAllContainers(context).exists[it instanceof Function]) {
					return super.getScope(context, reference)
				}

				val attribute = getContainerOfType(context, Attribute)
				val alias = EObjectDescription.create(QualifiedName.create('it'), attribute)

				new SimpleScope(newArrayList(alias))
			}
			default:
				super.getScope(context, reference)
		}
	}
}
