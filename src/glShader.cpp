#include "glShader.h"



GLShader::GLShader(void)
{
	m_shader = 0;
}

GLShader::~GLShader(void)
{
	DeleteShader();
}

void GLShader::DeleteShader()
{
	glDeleteProgram(m_shader);
	m_shader = 0;
}

GLuint GLShader::CompileShader(GLenum type, const GLchar *pszSource, GLint length)
{
	// Compiles the shader given it's source code. Returns the shader object.
	// A std::string object containing the shader's info log is thrown if the
	// shader failed to compile.
	//
	// 'type' is either GL_VERTEX_SHADER, GL_GEOMETRY_SHADER or GL_FRAGMENT_SHADER.
	// 'pszSource' is a C style string containing the shader's source code.
	// 'length' is the length of 'pszSource'.

	GLuint shader = glCreateShader(type);

	if (shader)
	{
		GLint compiled = 0;

		glShaderSource(shader, 1, &pszSource, &length);
		glCompileShader(shader);
		glGetShaderiv(shader, GL_COMPILE_STATUS, &compiled);

		if (!compiled)
		{
			GLsizei infoLogSize = 0;
			std::string infoLog;

			glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &infoLogSize);
			infoLog.resize(infoLogSize);
			glGetShaderInfoLog(shader, infoLogSize, &infoLogSize, &infoLog[0]);

			throw infoLog;
		}
	}
	return shader;
}

GLuint GLShader::LinkShaders(GLuint vertShader, GLuint geomShader, GLuint fragShader)
{
	// Links the compiled vertex and/or fragment shaders into an executable
	// shader program. Returns the executable shader object. If the shaders
	// failed to link into an executable shader program, then a std::string
	// object is thrown containing the info log.

	GLuint program = glCreateProgram();

	if (program)
	{
		GLint linked = 0;

		if (vertShader)
			glAttachShader(program, vertShader);

		if (geomShader)
			glAttachShader(program, geomShader);

		if (fragShader)
			glAttachShader(program, fragShader);

		glLinkProgram(program);
		glGetProgramiv(program, GL_LINK_STATUS, &linked);

		if (!linked)
		{
			GLsizei infoLogSize = 0;
			std::string infoLog;

			glGetProgramiv(program, GL_INFO_LOG_LENGTH, &infoLogSize);
			infoLog.resize(infoLogSize);
			glGetProgramInfoLog(program, infoLogSize, &infoLogSize, &infoLog[0]);

			throw infoLog;
		}

		// Mark the two attached shaders for deletion. These two shaders aren't
		// deleted right now because both are already attached to a shader
		// program. When the shader program is deleted these two shaders will
		// be automatically detached and deleted.

		if (vertShader)
			glDeleteShader(vertShader);

		if (geomShader)
			glDeleteShader(geomShader);

		if (fragShader)
			glDeleteShader(fragShader);
	}

	return program;
}


void GLShader::LoadShaderProgramFromFile(const char *filename)
{
    fprintf(stdout, "Compiling shader \"%s\".\n", filename);

    std::string infoLog;

	m_shader = 0;
	std::string buffer;

	// Read the text file containing the GLSL shader program.
	// This file contains 1 vertex shader and 1 fragment shader.
	ReadTextFileToBuffer(filename, buffer);

	// Compile and link the vertex and fragment shaders.
	if (buffer.length() > 0)
	{
		const GLchar *pSource = 0;
		GLint length = 0;
		GLuint vertShader = 0;
		GLuint geomShader = 0;
		GLuint fragShader = 0;

		std::string::size_type vertOffset = buffer.find("[vert]");
		std::string::size_type geomOffset = buffer.find("[geom]");
		std::string::size_type fragOffset = buffer.find("[frag]");
		
		std::string compilingErrorMsg;

		try
		{
			// Get the vertex shader source and compile it.
			// The source is between the [vert] and [geom] (or [frag]) tags.
			if (vertOffset != std::string::npos)
			{
				compilingErrorMsg = "Error in compiling the vertex shader:\n";
				vertOffset += 6;        // skip over the [vert] tag
				pSource = reinterpret_cast<const GLchar *>(&buffer[vertOffset]);
				std::string::size_type endVertOffset = 
					(geomOffset != std::string::npos) ? geomOffset : 
					((fragOffset != std::string::npos) ? fragOffset : buffer.length() - 1);
				length = static_cast<GLint>(endVertOffset - vertOffset);
				vertShader = CompileShader(GL_VERTEX_SHADER, pSource, length);
			}

			// Get the geometry shader source and compile it.
			// The source is between the [geom] and [frag] tags.
			if (geomOffset != std::string::npos)
			{
				compilingErrorMsg = "Error in compiling the geometry shader:\n";
				geomOffset += 6;        // skip over the [geom] tag
				pSource = reinterpret_cast<const GLchar *>(&buffer[geomOffset]);
				std::string::size_type endGeomOffset = 
					(fragOffset != std::string::npos) ? fragOffset : buffer.length() - 1;
				length = static_cast<GLint>(endGeomOffset - geomOffset);
				geomShader = CompileShader(GL_GEOMETRY_SHADER, pSource, length);
			}

			// Get the fragment shader source and compile it.
			// The source is between the [frag] tag and the end of the file.
			if (fragOffset != std::string::npos)
			{
				compilingErrorMsg = "Error in compiling the fragment shader:\n";
				fragOffset += 6;        // skip over the [frag] tag
				pSource = reinterpret_cast<const GLchar *>(&buffer[fragOffset]);
				length = static_cast<GLint>(buffer.length() - fragOffset - 1);
				fragShader = CompileShader(GL_FRAGMENT_SHADER, pSource, length);
			}


			compilingErrorMsg = "Error in linking the shaders:\n";
			// Now link the vertex and fragment shaders into a shader program.
			m_shader = LinkShaders(vertShader, geomShader, fragShader);

            fprintf(stdout, "Shader \"%s\" compiled successfully.\n", filename);
		}
		catch (const std::string &errors)
		{
			infoLog = compilingErrorMsg + errors;
            fprintf(stderr, "%s\n", infoLog.c_str());
            // throw std::runtime_error("Failed to load shader.\n" + infoLog);
		}

	}
	else
	{
		infoLog = std::string("Failed to load shader file ") + filename + ".\n";
        fprintf(stderr, "%s\n", infoLog.c_str());
        // throw std::runtime_error("Failed to load shader.\n" + infoLog);

	}

}

void GLShader::ReadTextFileToBuffer(const char *filename, std::string &buffer)
{
	FILE *fp;
	char *content = NULL;
	buffer.clear();

	int count=0;

	if (filename != NULL) {

		if (fopen_s(&fp, filename,"rt") == 0 && fp != NULL) {

			fseek(fp, 0, SEEK_END);
			count = ftell(fp);
			rewind(fp);

			if (count > 0) {
				content = new char[count+1];
				count = (int)fread(content,sizeof(char),count,fp);
				content[count] = '\0';
				buffer.assign(content, count);
				delete [] content;
			}
			fclose(fp);
		}
	}
}