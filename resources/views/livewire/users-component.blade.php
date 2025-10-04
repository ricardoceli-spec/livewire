<div class="container">
    {{-- Be like water. --}}
    <h1>{{$title}} ({{$users_count}})</h1>
    <button wire:click="click" class="btn btn-primary">Click</button>
    <br><br>

    <form wire:submit="crear_usuario">
        <div class="mb-2 col-sm-3" >
            <input type="text" placeholder="Nombre" wire:model="name" class="form-control @error('name') is-invalid @enderror" aria-describedby="vv">
            <div class="invalid-feedback" id="vv" >
                @error("name") <p>{{$message}}</p> @enderror
            </div>
           
           
        </div>
       
        <div class="mb-2 col-sm-3">    
            <input type="email" placeholder="Email" wire:model="email" class="form-control">
            @error("email") <p>{{$message}}</p> @enderror 
        </div>    
        <div class="mb-2 col-sm-3"> 
            <input type="password" placeholder="Contraseña" wire:model="password" class="form-control">
            @error("password") <p>{{$message}}</p> @enderror 
        </div>
        <button class="btn btn-primary mb-3">Crear usuario</button>
        <!-- <button wire:click="crear_usuario">Crear usuario</button> -->
    </form>
   
    
    <div class="mb-2 col-sm-3">    
        <input type="email" placeholder="Buscar..." wire:model.live="buscar" class="form-control">
       
    </div>   

    <table class="table table-striped table-hover table-hover table-bordered table-sm">
        <thead>
            <tr>
                <th scope="col">#</th>
                <th scope="col">Nombre</th>
                <th scope="col">Correo</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($registros as $fila)
            <tr>
                <td scope="row">{{$fila->id}}</td>
                <td>{{$fila->name}}</td>
                <td>{{$fila->email}}</td>            
            </tr>
            @endforeach 
        </tbody>
    </table>
</div>