using System;
using System.ComponentModel;

namespace Netco.Syntaxis
{
	/// <summary>
	/// Helper class for creating fluent APIs, that hides unused signatures
	/// </summary>
	[ Serializable ]
	public abstract class Syntax
	{
		/// <summary>
		/// Returns a <see cref="T:System.String"/> that represents the current <see cref="T:System.Object"/>.
		/// </summary>
		/// <returns>
		/// A <see cref="T:System.String"/> that represents the current <see cref="T:System.Object"/>.
		/// </returns>
		[ EditorBrowsable( EditorBrowsableState.Never ) ]
		public override string ToString()
		{
			return base.ToString();
		}

		/// <summary>
		/// Determines whether the specified <see cref="T:System.Object"/> is equal to the current <see cref="T:System.Object"/>.
		/// </summary>
		/// <param name="obj">The <see cref="T:System.Object"/> to compare with the current <see cref="T:System.Object"/>.</param>
		/// <returns>
		/// true if the specified <see cref="T:System.Object"/> is equal to the current <see cref="T:System.Object"/>; otherwise, false.
		/// </returns>
		/// <exception cref="T:System.NullReferenceException">
		/// The <paramref name="obj"/> parameter is null.
		/// </exception>
		[ EditorBrowsable( EditorBrowsableState.Never ) ]
		public override bool Equals( object obj )
		{
			return base.Equals( obj );
		}

		/// <summary>
		/// Serves as a hash function for a particular type.
		/// </summary>
		/// <returns>
		/// A hash code for the current <see cref="T:System.Object"/>.
		/// </returns>
		[ EditorBrowsable( EditorBrowsableState.Never ) ]
		public override int GetHashCode()
		{
			return base.GetHashCode();
		}

		/// <summary>
		/// Gets the <see cref="T:System.Type"/> of the current instance.
		/// </summary>
		/// <returns>
		/// The <see cref="T:System.Type"/> instance that represents the exact runtime type of the current instance.
		/// </returns>
		[ EditorBrowsable( EditorBrowsableState.Never ) ]
		public new Type GetType()
		{
			return base.GetType();
		}

		/// <summary>
		/// Creates the syntax for the specified target
		/// </summary>
		/// <typeparam name="TTarget">The type of the target.</typeparam>
		/// <param name="inner">The inner.</param>
		/// <returns>new syntax instance</returns>
		public static Syntax< TTarget > For< TTarget >( TTarget inner )
		{
			return new Syntax< TTarget >( inner );
		}

		/// <summary>
		/// Creates the syntax for the specified target
		/// </summary>
		/// <typeparam name="TTarget">The type of the target.</typeparam>
		/// <param name="inner">The inner.</param>
		/// <returns>new syntax instance</returns>
		public static SyntaxAsync< TTarget > ForAsync< TTarget >( TTarget inner )
		{
			return new SyntaxAsync< TTarget >( inner );
		}
	}
}